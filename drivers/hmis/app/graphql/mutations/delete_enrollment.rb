###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteEnrollment < BaseMutation
    argument :id, ID, required: true

    field :enrollment, Types::HmisSchema::Enrollment, null: true

    def resolve(id:)
      enrollment = Hmis::Hud::Enrollment.viewable_by(current_user).find_by(id: id)
      raise HmisErrors::ApiError, 'Record not found' unless enrollment.present?
      # WIP Enrollments can be deleted if user has "can_edit_enrollments" access for this project
      raise HmisErrors::ApiError, 'Access denied' unless current_user.permissions_for?(enrollment, :can_edit_enrollments)

      errors = []
      if enrollment.in_progress?
        enrollment.destroy!
      elsif !enrollment.intake_assessment
        # Non-WIP, Active Enrollments can be destroyed if there is no associated intake assessment
        # (either due to data being migrated in, or if we support projects that don't do assessments in future).
        # This requires can_delete_enrollments permission.
        raise HmisErrors::ApiError, 'Access denied' unless current_user.permissions_for?(enrollment, :can_delete_enrollments)

        enrollment.destroy!
      else
        # Deleting non-WIP Enrollments with Intake Assessment can only occur via DeleteAssessment mutation (deleting intake)
        errors << HmisErrors::Error.new(:base, full_message: 'Completed enrollments can not be deleted. Please exit the client instead.')
      end

      {
        enrollment: enrollment,
        errors: errors,
      }
    end
  end
end
