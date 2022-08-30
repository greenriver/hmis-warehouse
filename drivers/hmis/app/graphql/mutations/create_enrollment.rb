module Mutations
  class CreateEnrollment < BaseMutation
    argument :input, Types::HmisSchema::CreateEnrollmentValues, required: true

    field :enrollments, [Types::HmisSchema::Enrollment], null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(input:)
      errors = []

      enrollments = input.to_enrollments_params.map do |attrs|
        enrollment = Hmis::Hud::Enrollment.new(attrs)

        if enrollment.valid?
          enrollment.save!
        else
          enrollment.in_progress = true
          enrollment.save!(validate: false)
        end

        errors += enrollment.errors

        enrollment
      end

      {
        enrollments: enrollments,
        errors: errors,
      }
    end
  end
end
