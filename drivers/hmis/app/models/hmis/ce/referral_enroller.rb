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
      project = referral.target_project

      # Step form may specify CoC code. This is required if the Project serves multiple CoCs.
      coc_code_arg = message.step&.submitted_values&.fetch(COC_CODE_LINK_ID, nil)
      coc_code = project.determine_coc_code(coc_code_arg: coc_code_arg)

      # TODO(#7321) - carry over the client's household members from the source enrollment

      enrollment = Hmis::Hud::Enrollment.new(
        client: referral.client,
        project: project,
        entry_date: Date.current,
        user: Hmis::Hud::User.from_user(message.user),
        household_id: Hmis::Hud::Base.generate_uuid,
        relationship_to_hoh: 1, # Head of Household
        enrollment_coc: coc_code,
      )
      raise 'referral generated invalid enrollment' unless enrollment.valid?

      # Raise an exception if there are any entry date validation errors, which may mean that the client is already enrolled at the project.
      # Future improvement would be to return this as a validation error instead of raising
      entry_date_errors = Hmis::Hud::Validators::EnrollmentValidator.validate_entry_date(enrollment)
      entry_date_errors.reject!(&:warning?)
      error_out(entry_date_errors.map(&:full_message).join(', ')) unless entry_date_errors.empty?

      # TODO(#7537) - prevent conflicting unit occupancy
      unit = referral.opportunity.unit
      enrollment.assign_unit(unit: unit, start_date: Date.current, user: message.user) if unit.is_a? Hmis::Unit

      enrollment.save_new_enrollment! # Saves as WIP or non-WIP, depending on auto-enter rules in the project
      referral.update!(target_enrollment: enrollment)
    end

    # Sets the Move-In Date on the target enrollments, based on a date value collected on the step form.
    #
    # This requires a Move-in date item to be on the step form with the following attributes:
    #    { "link_id": "move_in_date", "type": "DATE", "mapping": { "custom_field_key": "<any field key for storing date value>" } }
    #
    # Note: We do a lookup by link_id rather than by mapping:field_name to prevent the FormProcessor from attempting
    # to process the move_in_date field. That would be another approach, but we decided against it in favor of having an
    # explicit trigger to populate the collected date onto the move_in_date field. In part because, when you go back and
    # view a previously submitted task, it should show the Move-in Date as it was when the task was performed, NOT
    # the current value of the Move-in Date field on the target enrollment. To achieve this, the date recorded on the task
    # would be additionally stored in the CustomDataElement field.
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

    def error_out(msg)
      # error out with user-facing error message
      raise HmisErrors::ApiError.new(msg, display_message: msg)
    end
  end
end
