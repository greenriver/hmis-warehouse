###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class DeleteEnrollment < BaseMutation
    include DeletesHouseholdEnrollments

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

      # If this is the HoH, delete all household enrollments to avoid leaving behind a household with no HoH
      if enrollment.head_of_household?
        destroy_household!(hoh_enrollment: enrollment)
      else
        enrollment.destroy!
      end

      {
        enrollment: enrollment,
      }
    end
  end
end
