# frozen_string_literal: true

module Hmis::Ce
  class ReferralEnroller
    attr_reader :referral
    def initialize(referral)
      @referral = referral
    end

    def create_enrollment(message, user)
      project = referral.opportunity.project
      raise 'access denied' unless user.can_enroll_clients_for?(project)

      submitted_values = message.step&.submitted_values&.symbolize_keys
      coc_code_arg = submitted_values ? submitted_values[:coc_code] : nil
      coc_code = project.determine_coc_code(coc_code_arg: coc_code_arg)

      # TODO(#7321) - carry over the client's household members from the source enrollment

      enrollment = Hmis::Hud::Enrollment.new(
        client: referral.client,
        project: project,
        entry_date: Date.current,
        user: Hmis::Hud::User.from_user(user),
        household_id: Hmis::Hud::Base.generate_uuid,
        relationship_to_hoh: 1, # Head of Household
        enrollment_coc: coc_code,
      )
      raise 'referral generated invalid enrollment' unless enrollment.valid?

      entry_date_errors = Hmis::Hud::Validators::EnrollmentValidator.validate_entry_date(enrollment)
      entry_date_errors.reject! { |e| e.warning? && e.type == :information }
      error_out(entry_date_errors.first.full_message) unless entry_date_errors.empty?

      # TODO(#6709) - assign enrollment to unit

      enrollment.save_new_enrollment! # Saves as WIP or non-WIP, depending on auto-enter rules in the project
      referral.update!(target_household: enrollment.household)
    end

    def set_move_in_date(message, user)
      project = referral.opportunity.project
      raise 'access denied' unless user.can_edit_enrollments_for?(project)

      # This doesn't raise if the move-in date is missing. If the field is required, it should have already been caught by form validation.
      submitted_values = message.step&.submitted_values&.symbolize_keys
      date_string = submitted_values ? submitted_values[:move_in_date] : nil
      return unless date_string.present?

      raise "Trying to set move-in date, but referral #{referral.id} does not have a target household yet. This probably indicates a mistake in the workflow configuration." unless referral.target_household.present?

      enrollment = referral.target_household.enrollments.where(relationship_to_hoh: 1).order(:id).first
      date = HmisUtil::Dates.safe_parse_date(date_string: date_string)
      enrollment.update!(move_in_date: date)
    end

    private

    def error_out(msg)
      # error out with user-facing error message
      raise HmisErrors::ApiError.new(msg, display_message: msg)
    end
  end
end
