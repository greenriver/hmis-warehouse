module Mutations
  class AddHouseholdMembersToEnrollment < BaseMutation
    argument :household_id, ID, required: true
    date_string_argument :start_date, 'Start date with format yyyy-mm-dd', required: true
    argument :household_members, [Types::HmisSchema::EnrollmentHouseholdMemberInput], required: true

    field :enrollments, [Types::HmisSchema::Enrollment], null: true

    def validate_input(household_id:, start_date:, household_members:)
      errors = HmisErrors::Errors.new
      errors.add :start_date, :out_of_range, message: 'cannot be in the future', readable_attribute: 'Entry date' if Date.parse(start_date) > Date.today

      has_enrollment = Hmis::Hud::Enrollment.editable_by(current_user).exists?(household_id: household_id)
      has_hoh_enrollment = Hmis::Hud::Enrollment.editable_by(current_user).exists?(
        household_id: household_id,
        relationship_to_ho_h: 1,
      )

      errors.add :household_id, :invalid, full_message: "Cannot find Enrollment for household with id '#{household_id}'" unless has_enrollment

      errors.add :household_members, :invalid, full_message: 'Enrollment already has a Head of Household designated' if has_hoh_enrollment && household_members.find { |hm| hm.relationship_to_ho_h == 1 }

      errors
    end

    def resolve(household_id:, start_date:, household_members:)
      errors = validate_input(household_id: household_id, start_date: start_date, household_members: household_members)
      return { errors: errors } if errors.any?

      existing_enrollment = Hmis::Hud::Enrollment.editable_by(current_user).find_by(household_id: household_id)
      lookup = Hmis::Hud::Client.where(id: household_members.map(&:id)).index_by(&:id)
      project_id = existing_enrollment.project.project_id

      enrollments = household_members.map do |household_member|
        client = lookup[household_member.id.to_i]
        enrollment = client.enrollments.editable_by(current_user).find_by(household_id: household_id)

        next enrollment if enrollment.present?

        Hmis::Hud::Enrollment.new(
          data_source_id: hmis_user.data_source_id,
          user_id: hmis_user.user_id,
          personal_id: client.personal_id,
          relationship_to_ho_h: household_member.relationship_to_ho_h,
          entry_date: start_date,
          project_id: project_id,
          household_id: household_id,
          enrollment_id: Hmis::Hud::Enrollment.generate_enrollment_id,
        )
      end

      errors = []
      enrollments.each(&:valid?).each do |enrollment|
        errors += enrollment.errors.errors unless enrollment.errors.empty?
      end
      return { errors: errors } if errors.any?

      enrollments.each(&:save_in_progress)

      {
        enrollments: enrollments,
        errors: [],
      }
    end
  end
end
