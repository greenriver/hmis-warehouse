###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Ce
  class ReferralEnroller
    MOVE_IN_DATE_LINK_ID = 'move_in_date'
    COC_CODE_LINK_ID = 'coc_code'

    attr_reader :referral

    def initialize(referral)
      @referral = referral
    end

    def create_enrollment(message)
      raise "Referral #{referral.id} already has an enrollment. This indicates a misconfigured workflow" if referral.target_enrollment

      project = referral.target_project

      # Step form may specify CoC code. This is required if the Project serves multiple CoCs.
      coc_code_arg = message.step&.submitted_values&.fetch(COC_CODE_LINK_ID, nil)
      coc_code = project.determine_coc_code(coc_code_arg: coc_code_arg)

      # clients_to_enroll is a map of Hmis::Hud::Client to their Relationship to HoH, including the referred client (HoH).
      clients_to_enroll = get_clients_to_enroll(referral.source_enrollment)

      # Generate a new household ID for the target enrollment household
      new_household_id = Hmis::Hud::Base.generate_uuid
      hud_user = Hmis::Hud::User.from_user(message.user)
      entry_date = Date.current
      unit = referral.opportunity.unit

      validation_errors = []

      # If there are household members to enroll, create enrollments for all of them
      enrollments = clients_to_enroll.map do |client, relationship_to_hoh|
        enrollment = Hmis::Hud::Enrollment.new(
          client: client,
          project: project,
          entry_date: entry_date,
          user: hud_user,
          household_id: new_household_id,
          relationship_to_hoh: relationship_to_hoh,
          enrollment_coc: coc_code,
        )

        raise 'referral generated invalid enrollment' unless enrollment.valid?

        # Validate entry date
        entry_date_errors = Hmis::Hud::Validators::EnrollmentValidator.validate_entry_date(enrollment)
        entry_date_errors.reject!(&:warning?)
        validation_errors.concat(entry_date_errors)

        enrollment
      end

      error_out(validation_errors.map(&:full_message).join(', ')) unless validation_errors.empty?

      # Save the HoH's (referred client's) enrollment and associate it with the referral.
      # Do this before saving the hh member enrollments, so that assign_unit validations pass.
      hoh_target_enrollment = enrollments.find { |e| e.client == referral.client }
      enrollments.delete(hoh_target_enrollment) # Remove from list so it's not saved again below
      hoh_target_enrollment.assign_unit(unit: unit, start_date: entry_date, user: message.user)
      hoh_target_enrollment.save_new_enrollment! # Saves as WIP or non-WIP, depending on auto-enter rules in the project
      referral.update!(target_enrollment: hoh_target_enrollment)

      # Assign household members and save
      enrollments.each do |enrollment|
        enrollment.assign_unit(unit: unit, start_date: entry_date, user: message.user)
        enrollment.save_new_enrollment!
      end
    end

    def delete_wip_enrollment(_message) # todo @martha - needs to be updated
      enrollment = referral.target_enrollment
      return unless enrollment

      unless enrollment.in_progress?
        message = "target enrollment #{enrollment.id} has already had intake completed, unable to perform delete_wip_enrollment message"
        raise message if Rails.env.development?

        Sentry.capture_message(message)
        return # in non-dev env: return, we are unable to perform the action
      end

      referral.update!(target_enrollment: nil)
      enrollment.destroy!
    end

    # Sets the Move-In Date on the target enrollment, based on a date value collected on the step form.
    # This requires a Move-in date item to be on the step form with the following attributes:
    # { "link_id": "move_in_date", "type": "DATE", "mapping": { "custom_field_key": "" } }
    #
    # - item must have the exact link_id `move_in_date` to trigger this side effect
    # - item must additionally save the value to a custom data element
    # We chose this approach, rather than using "mapping": { "record_type": "ENROLLMENT", "field_name": "moveInDate" },
    # because the form should show show the Move-in Date as it was when the task was performed, NOT the current value
    # of the Move-in Date field on the target enrollment.
    def set_move_in_date(message) # rubocop:disable Naming/AccessorMethodName
      # Validate that the form collects move-in date using the MOVE_IN_DATE_LINK_ID
      form_definition = message.step.form_definition
      raise "Trying to set move-in date for referral #{referral.id}, step #{message.step.id}, but form definition '#{form_definition.identifier}' doesn't collect it. This probably indicates a mistake in the workflow configuration. The form must collect move-in date on an item with link_id '#{MOVE_IN_DATE_LINK_ID}'" unless form_definition.link_id_item_hash[MOVE_IN_DATE_LINK_ID].present?

      # Find the form item corresponding to move-in date
      date_string = message.step&.submitted_values&.fetch(MOVE_IN_DATE_LINK_ID, nil)

      # This doesn't raise if the move-in date is missing. If the field is required, it should have already been caught by form validation.
      return unless date_string.present?

      date = HmisUtil::Dates.safe_parse_date(date_string: date_string)
      raise "Failed to parse move-in date value collected on referral step form '#{form_definition.identifier}'" unless date

      enrollment = referral.target_enrollment
      raise "Trying to set move-in date, but referral #{referral.id} does not have a target enrollment yet. This probably indicates a mistake in the workflow configuration." unless enrollment.present?

      # No need to check permission for editing the enrollment.
      # If the user can complete this step, they can do its side effects, even if they don't have direct permission
      enrollment.update!(move_in_date: date)
    end

    private

    # Get the list of clients to enroll in the target project.
    # Returns a map of Hmis::Hud::Client to integer values representing the Relationship to HoH.
    def get_clients_to_enroll(source_enrollment)
      clients_to_enroll = { referral.client => 1 }

      # If no source enrollment, only enroll the referred client.
      # (Not yet relevant in practice, but db col is nullable to accommodate future flexibility)
      return clients_to_enroll unless source_enrollment

      # If the source enrollment is exited from the household, only enroll the referred client.
      # (Edge case: If the whole household has been exited, household members won't be enrolled.)
      return clients_to_enroll if source_enrollment.exit&.present?

      # Add all non-exited household members from the source enrollment (including incomplete/WIP enrollments)
      source_enrollment.household_members.
        open_including_wip.
        preload(:client).
        where.not(client: referral.client).
        each do |household_member|
          # If the referred client is still the HoH in the source household, carry over the original relationship.
          # Otherwise, set relationship to 99 (Data not collected) so it can be flagged in data quality reports.
          relationship_to_hoh = source_enrollment.head_of_household? ? household_member.relationship_to_hoh : 99
          clients_to_enroll[household_member.client] = relationship_to_hoh
        end

      clients_to_enroll
    end

    def error_out(msg)
      # error out with user-facing error message
      raise HmisErrors::ApiError.new(msg, display_message: msg)
    end
  end
end
