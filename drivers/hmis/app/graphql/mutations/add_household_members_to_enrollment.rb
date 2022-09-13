module Mutations
  class AddHouseholdMembersToEnrollment < BaseMutation
    argument :household_id, ID, required: true
    date_string_argument :start_date, 'Start date with format yyyy-mm-dd', required: true
    argument :household_members, [Types::HmisSchema::EnrollmentHouseholdMemberInput], required: true

    field :enrollments, [Types::HmisSchema::Enrollment], null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def validate_input(household_id:, start_date:, household_members:)
      errors = []
      errors << InputValidationError.new('Entry date cannot be in the future', attribute: 'start_date') if Date.parse(start_date) > Date.today

      has_enrollment = Hmis::Hud::Enrollment.viewable_by(current_user).exists?(household_id: household_id)
      has_hoh_enrollment = Hmis::Hud::Enrollment.viewable_by(current_user).exists?(household_id: household_id, relationship_to_ho_h: 1)
      errors << InputValidationError.new("Cannot find Enrollment for household with id '#{household_id}'", attribute: 'household_id') unless has_enrollment
      errors << InputValidationError.new('Enrollment already has a head of household designated', attribute: 'household_members') if has_hoh_enrollment && household_members.find { |hm| hm.relationship_to_ho_h == 1 }

      errors
    end

    def resolve(household_id:, start_date:, household_members:)
      user = current_user
      errors = validate_input(household_id: household_id, start_date: start_date, household_members: household_members)

      if errors.present?
        return {
          enrollments: [],
          errors: errors,
        }
      end

      existing_enrollment = Hmis::Hud::Enrollment.viewable_by(user).find_by(household_id: household_id)
      lookup = Hmis::Hud::Client.where(id: household_members.map(&:id)).index_by(&:id)
      project = existing_enrollment.project

      enrollments = household_members.map do |household_member|
        client = lookup[household_member.id.to_i]
        enrollment = client.enrollments.viewable_by(user).find_by(household_id: household_id)

        next enrollment if enrollment.present?

        enrollment = Hmis::Hud::Enrollment.new(
          data_source_id: hmis_user.data_source_id,
          personal_id: client.personal_id,
          relationship_to_ho_h: household_member.relationship_to_ho_h,
          entry_date: start_date,
          project_id: project&.project_id,
          household_id: household_id,
          enrollment_id: Hmis::Hud::Enrollment.generate_enrollment_id,
        )
        enrollment.save_in_progress

        enrollment
      end

      enrollments.each(&:valid?).each do |enrollment|
        errors += enrollment.errors.errors unless enrollment.errors.empty?
      end

      {
        enrollments: enrollments,
        errors: errors,
      }
    end
  end
end
