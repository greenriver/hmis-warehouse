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
      raise HmisErrors::ApiError, 'Access denied' unless current_user.permissions_for?(enrollment, :can_delete_enrollments)

      errors = []
      if enrollment.in_progress?
        enrollment.destroy
      else
        errors << HmisErrors::Error.new(:base, full_message: 'Completed enrollments can not be deleted. Please exit the client instead.')
      end

      {
        enrollment: enrollment,
        errors: errors,
      }
    end
  end
end
