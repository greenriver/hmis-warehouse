module Mutations
  class CreateEnrollment < BaseMutation
    argument :input, Types::HmisSchema::CreateEnrollmentValues, required: true

    field :enrollments, [Types::HmisSchema::Enrollment], null: true
    field :errors, [Types::HmisSchema::ErrorGroup], null: false

    def resolve(input:)
      user = hmis_user
      errors = []

      if input.household_members.select { |hm| hm.relationship_to_ho_h == 1 }.size != 1
        return {
          enrollments: [],
          errors: [
            {
              id: 'input',
              errors: [
                ArgumentError.new('Exactly one client must be head of household'),
              ],
            },
          ],
        }
      end

      if Date.parse(input.start_date) > Date.today
        return {
          enrollments: [],
          errors: [
            {
              id: 'input',
              errors: [
                ArgumentError.new('Entry date cannot be in the future'),
              ],
            },
          ],
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

        errors << { id: enrollment.id, class_name: enrollment.class.name, errors: enrollment.errors } unless enrollment.errors.empty?

        enrollment
      end

      {
        enrollments: enrollments,
        errors: errors,
      }
    end
  end
end
