###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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
        with_paper_trail_meta(**enrollment.paper_trail_info_for_mutation) do
          enrollment.destroy!
        end
      else
        # Deleting non-WIP Enrollments requires can_delete_enrollments, and can only occur via DeleteAssessment mutation (deleting intake)
        errors << HmisErrors::Error.new(:base, full_message: 'Completed enrollments can not be deleted. Please exit the client instead.')
      end

      {
        enrollment: enrollment,
        errors: errors,
      }
    end
  end
end
