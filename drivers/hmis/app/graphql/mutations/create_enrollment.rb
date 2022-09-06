module Mutations
  class CreateEnrollment < BaseMutation
    argument :input, Types::HmisSchema::CreateEnrollmentValues, required: true

    field :enrollments, [Types::HmisSchema::Enrollment], null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def validate_input(input)
      errors = []
      errors << InputValidationError.new('Exactly one client must be head of household', attribute: 'relationship_to_ho_h') if input.household_members.select { |hm| hm.relationship_to_ho_h == 1 }.size != 1
      errors << InputValidationError.new('Entry date cannot be in the future', attribute: 'start_date') if Date.parse(input.start_date) > Date.today
      errors << InputValidationError.new("Project with id '#{input.project_id}' does not exist", attribute: 'project_id') unless Hmis::Hud::Project.viewable_by(current_user).exists?(id: input.project_id)
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
          enrollment.save_not_in_progress
        else
          enrollment.save_in_progress
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
