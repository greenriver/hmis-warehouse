module Mutations
  class CreateEnrollment < BaseMutation
    argument :project_id, ID, required: true
    date_string_argument :start_date, 'Start date with format yyyy-mm-dd', required: true
    argument :household_members, [Types::HmisSchema::EnrollmentHouseholdMemberInput], required: true
    argument :in_progress, Boolean, required: false

    field :enrollments, [Types::HmisSchema::Enrollment], null: true

    def validate_input(project_id:, start_date:, household_members:)
      errors = HmisErrors::Errors.new
      errors.add :relationship_to_ho_h, full_message: 'Exactly one client must be head of household' if household_members.select { |hm| hm.relationship_to_ho_h == 1 }.size != 1
      errors.add :start_date, :out_of_range, message: 'cannot be in the future', readable_attribute: 'Entry date' if Date.parse(start_date) > Date.today
      errors.add :project_id, :not_found unless Hmis::Hud::Project.editable_by(current_user).exists?(id: project_id)
      errors.errors
    end

    def to_enrollments_params(project_id:, start_date:, household_members:, in_progress: false)
      result = []
      household_id = Hmis::Hud::Enrollment.generate_household_id
      lookup = Hmis::Hud::Client.where(id: household_members.map(&:id)).pluck(:id, :personal_id).to_h
      project = Hmis::Hud::Project.editable_by(context[:current_user]).find_by(id: project_id)

      household_members.each do |household_member|
        result << {
          personal_id: lookup[household_member.id.to_i],
          relationship_to_ho_h: household_member.relationship_to_ho_h,
          entry_date: start_date,
          project_id: project&.project_id,
          household_id: household_id,
          enrollment_id: Hmis::Hud::Enrollment.generate_enrollment_id,
          in_progress: in_progress,
        }
      end

      result
    end

    def resolve(project_id:, start_date:, household_members:, in_progress: false)
      user = hmis_user
      errors = validate_input(project_id: project_id, start_date: start_date, household_members: household_members)
      return { enrollments: [], errors: errors } if errors.any?

      enrollments = to_enrollments_params(project_id: project_id, start_date: start_date, household_members: household_members, in_progress: in_progress).map do |attrs|
        enrollment = Hmis::Hud::Enrollment.new(
          user_id: user.user_id,
          data_source_id: user.data_source_id,
          **attrs,
        )

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
