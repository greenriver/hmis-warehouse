module Mutations
  class DeleteEnrollment < BaseMutation
    argument :id, ID, required: true

    field :enrollment, Types::HmisSchema::Enrollment, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(id:)
      errors = []
      enrollment = Hmis::Hud::Enrollment.viewable_by(current_user).find_by(id: id)

      if enrollment.present?
        if enrollment.in_progress?
          enrollment.destroy
        else
          errors << InputValidationError.new('Only in-progress enrollments can be deleted')
        end

        errors << enrollment.errors.errors unless enrollment.valid?
      else
        errors << InputValidationError.new("No enrollment found with ID '#{id}'", attribute: 'id')
      end

      {
        enrollment: enrollment,
        errors: errors,
      }
    end
  end
end
