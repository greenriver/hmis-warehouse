###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Ce
  class ReferralEnroller
    # If this link id is used on a referral workflow form, the engine will attempt to store the value on the target Enrollment
    # (and raise if there is no target enrollment).
    MOVE_IN_DATE_LINK_ID = 'move_in_date'
    # TODO(#7485): Use mappings, similar to assessment processing

    attr_reader :referral

    def initialize(referral)
      @referral = referral
    end

    def create_enrollment(message)
      project = referral.target_project
      raise 'access denied' unless message.user.can_enroll_clients_for?(project)

      # Step form may specify CoC code. This is required if the Project serves multiple CoCs.
      coc_code_arg = message.step&.submitted_values&.fetch('coc_code', nil)
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

      # TODO(#6709) - assign enrollment to unit

      enrollment.save_new_enrollment! # Saves as WIP or non-WIP, depending on auto-enter rules in the project
      referral.update!(target_enrollment: enrollment)
    end

    # this is not actually an accessor method, even though RuboCop thinks it is
    def set_move_in_date(message) # rubocop:disable Naming/AccessorMethodName
      project = referral.target_project
      raise 'access denied' unless message.user.can_edit_enrollments_for?(project)

      # This doesn't raise if the move-in date is missing. If the field is required, it should have already been caught by form validation.
      date_string = message.step&.submitted_values&.fetch(MOVE_IN_DATE_LINK_ID, nil)
      return unless date_string.present?

      date = HmisUtil::Dates.safe_parse_date(date_string: date_string)
      return unless date.present?

      enrollment = referral.target_enrollment
      raise "Trying to set move-in date, but referral #{referral.id} does not have a target enrollment yet. This probably indicates a mistake in the workflow configuration." unless enrollment.present?

      enrollment.update!(move_in_date: date)
    end

    private

    def error_out(msg)
      # error out with user-facing error message
      raise HmisErrors::ApiError.new(msg, display_message: msg)
    end
  end
end
