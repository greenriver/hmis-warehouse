module Mutations
  class DeleteEnrollment < BaseMutation
    argument :id, ID, required: true

    field :enrollment, Types::HmisSchema::Enrollment, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(id:)
      errors = []
      enrollment = Hmis::Hud::Enrollment.editable_by(current_user).find_by(id: id)

      if enrollment.present?
        if enrollment.in_progress?
          enrollment.destroy
        else
          errors << Errors::CustomValidationError.new(:base, full_message: 'Completed enrollments can not be deleted. Please exit the client instead.')
        end

        errors << enrollment.errors.errors unless enrollment.valid?
      else
        errors << Errors::CustomValidationError.new(:enrollment, :not_found)
      end

      {
        enrollment: enrollment,
        errors: errors,
      }
    end
  end
end
