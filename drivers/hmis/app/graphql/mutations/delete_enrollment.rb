###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class DeleteEnrollment < BaseMutation
    argument :id, ID, required: true

    field :enrollment, Types::HmisSchema::Enrollment, null: true

    def resolve(id:)
      enrollment = Hmis::Hud::Enrollment.viewable_by(current_user).find_by(id: id)
      raise HmisErrors::ApiError, 'Record not found' unless enrollment.present?

      errors = []
      policy = policy_for(enrollment, policy_type: :hmis_enrollment)

      if !enrollment.in_progress? && enrollment.intake_assessment
        # Deleting non-WIP Enrollments with Intake Assessment can only occur via DeleteAssessment mutation (deleting intake)
        errors << HmisErrors::Error.new(:base, full_message: 'Completed enrollments can not be deleted. Please exit the client instead.')
        return { errors: errors, enrollment: enrollment }
      end

      # WIP Enrollments, and enrollments missing intakes (such as migrated-in data), can be deleted
      access_denied! unless policy.can_delete?

      delete_household_enrollments(enrollment: enrollment)

      {
        enrollment: enrollment,
      }
    end

    def delete_household_enrollments(enrollment:)
      enrollments_to_delete = [enrollment]

      # If we're deleting the HoH enrollment, delete all household members' enrollments too.
      # This avoids leaving a dangling household without a HoH.
      if enrollment.head_of_household?
        enrollment.household_members.each do |hhm_enrollment|
          # Check if the user has permission to delete each enrollment. This deals with the hypothetical edge case:
          # If the HoH's enrollment is in-progress, but another HHM has a completed intake (non-WIP),
          # the current user might not have the right permission (can_delete_enrollments) to delete all the enrollments.
          # (This would likely be a data issue from import, since our frontend disallows submitting the HHM intakes before the HoH.)
          access_denied! unless policy_for(hhm_enrollment, policy_type: :hmis_enrollment).can_delete?

          enrollments_to_delete.append(hhm_enrollment)
        end
      end

      Hmis::Hud::Enrollment.transaction do
        enrollments_to_delete.uniq.each(&:destroy!)
      end
    end
  end
end
