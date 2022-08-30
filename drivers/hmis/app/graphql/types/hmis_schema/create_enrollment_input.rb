module Types
  class HmisSchema::EnrollmentHouseholdMemberInput
    description 'HMIS Enrollment household member input'

    argument :id, ID, required: true
    argument :relationship_to_ho_h, HmisSchema::Enums::RelationshipToHoH, required: true
  end

  class HmisSchema::CreateEnrollmentInput < BaseInputObject
    description 'HMIS Enrollment creation input'

    argument :project_id, ID, required: false
    argument :start_date, String, 'Start date with format yyyy-mm-dd', required: false
    argument :household_members, [HmisSchema::EnrollmentHouseholdMemberInput], required: true
    argument :in_progress, Boolean, required: false

    def to_params
      result = to_h.except(:start_date)
      result[:start_date] = Date.strptime(start_date, '%Y-%m-%d') if start_date.present?

      result
    end

    def to_enrollments
      result = []

      household_members.each do |_household_member|
        result << {
          # TODO
          **to_params.except(:household_members),
        }
      end

      result
    end
  end
end
