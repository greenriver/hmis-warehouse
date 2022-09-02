module Mutations
  class CreateEnrollment < BaseMutation
    argument :input, Types::HmisSchema::CreateEnrollmentValues, required: true

    field :enrollments, [Types::HmisSchema::Enrollment], null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def validate_input(input)
      errors = []
      errors << ArgumentError.new('Exactly one client must be head of household') if input.household_members.select { |hm| hm.relationship_to_ho_h == 1 }.size != 1
      errors << ArgumentError.new('Entry date cannot be in the future') if Date.parse(input.start_date) > Date.today
      errors
    end

    def resolve(input:)
      user = hmis_user
      errors = validate_input(input)

      if errors.present?
        return {
          enrollments: [],
          errors: errors,
        }
      end

      enrollments = input.to_enrollments_params.map do |attrs|
        enrollment = Hmis::Hud::Enrollment.new(data_source_id: user.data_source_id, **attrs)

        if enrollment.valid? && !enrollment.in_progress?
          enrollment.save!
        else
          enrollment.in_progress = true
          enrollment.save(validate: false)
        end

        errors += enrollment.errors.errors unless enrollment.errors.empty?

        enrollment
      end

      {
        enrollments: enrollments,
        errors: errors,
      }
    end
  end
end
