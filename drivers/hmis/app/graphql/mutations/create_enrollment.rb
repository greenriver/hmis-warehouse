module Mutations
  class CreateEnrollment < BaseMutation
    argument :project_id, ID, required: true
    date_string_argument :start_date, 'Start date with format yyyy-mm-dd', required: true
    argument :household_members, [Types::HmisSchema::EnrollmentHouseholdMemberInput], required: true
    argument :in_progress, Boolean, required: false

    field :enrollments, [Types::HmisSchema::Enrollment], null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def validate_input(project_id:, start_date:, household_members:)
      errors = []
      errors << InputValidationError.new('Exactly one client must be head of household', attribute: 'relationship_to_ho_h') if household_members.select { |hm| hm.relationship_to_ho_h == 1 }.size != 1
      errors << InputValidationError.new('Entry date cannot be in the future', attribute: 'start_date') if Date.parse(start_date) > Date.today
      errors << InputValidationError.new("Project with id '#{project_id}' does not exist", attribute: 'project_id') unless Hmis::Hud::Project.viewable_by(current_user).exists?(id: project_id)
      errors
    end

    def to_enrollments_params(project_id:, start_date:, household_members:, in_progress: false)
      result = []
      household_id = SecureRandom.uuid.gsub(/-/, '')
      lookup = Hmis::Hud::Client.where(id: household_members.map(&:id)).pluck(:id, :personal_id).to_h
      project = Hmis::Hud::Project.viewable_by(context[:current_user]).find_by(id: project_id)

      household_members.each do |household_member|
        result << {
          personal_id: lookup[household_member.id.to_i],
          relationship_to_ho_h: household_member.relationship_to_ho_h,
          entry_date: Date.strptime(start_date, '%Y-%m-%d'),
          project_id: project&.project_id,
          household_id: household_id,
          enrollment_id: SecureRandom.uuid.gsub(/-/, ''),
          in_progress: in_progress,
        }
      end

      result
    end

    def resolve(project_id:, start_date:, household_members:, in_progress: false)
      user = hmis_user
      errors = validate_input(project_id: project_id, start_date: start_date, household_members: household_members)

      if errors.present?
        return {
          enrollments: [],
          errors: errors,
        }
      end

      enrollments = to_enrollments_params(project_id: project_id, start_date: start_date, household_members: household_members, in_progress: in_progress).map do |attrs|
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
