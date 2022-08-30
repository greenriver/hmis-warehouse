module Mutations
  class CreateEnrollment < BaseMutation
    argument :input, Types::HmisSchema::CreateEnrollmentValues, required: true

    field :enrollments, [Types::HmisSchema::Enrollment], null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(input:)
      user = hmis_user
      errors = []

      enrollments = input.to_enrollments_params.map do |attrs|
        enrollment = Hmis::Hud::Enrollment.new(data_source_id: user.data_source_id, **attrs)

        if enrollment.valid? && !enrollment.in_progress?
          enrollment.save!
        else
          enrollment.in_progress = true
          enrollment.save!(validate: false)
        end

        errors += enrollment.errors.to_a

        enrollment
      end

      {
        enrollments: enrollments,
        errors: errors,
      }
    end
  end
end
