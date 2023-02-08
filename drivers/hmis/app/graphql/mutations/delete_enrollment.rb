module Mutations
  class DeleteEnrollment < BaseMutation
    argument :id, ID, required: true

    field :enrollment, Types::HmisSchema::Enrollment, null: true

    def resolve(id:)
      errors = []
      enrollment = Hmis::Hud::Enrollment.editable_by(current_user).find_by(id: id)

      if enrollment.present?
        if enrollment.in_progress?
          enrollment.destroy
        else
          errors << HmisErrors::Error.new(:base, full_message: 'Completed enrollments can not be deleted. Please exit the client instead.')
        end

        errors << enrollment.errors.errors unless enrollment.valid?
      else
        errors << HmisErrors::Error.new(:enrollment, :not_found)
      end

      {
        enrollment: enrollment,
        errors: errors,
      }
    end
  end
end
