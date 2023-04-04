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

      return { errors: [HmisErrors::Error.new(:enrollment, :not_found)] } unless enrollment.present?
      return { errors: [HmisErrors::Error.new(:enrollment, :not_allowed)] } unless current_user.permissions_for?(enrollment, :can_delete_enrollments)

      errors = []
      if enrollment.in_progress?
        enrollment.destroy
      else
        errors << HmisErrors::Error.new(:base, full_message: 'Completed enrollments can not be deleted. Please exit the client instead.')
      end

      errors << enrollment.errors.errors unless enrollment.valid?

      {
        enrollment: enrollment,
        errors: errors,
      }
    end
  end
end
