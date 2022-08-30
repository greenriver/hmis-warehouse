module Types
  class HmisSchema::EnrollmentHouseholdMemberInput < BaseInputObject
    description 'HMIS Enrollment household member input'

    argument :id, ID, required: true
    argument :relationship_to_ho_h, HmisSchema::Enums::RelationshipToHoH, required: true
  end

  class HmisSchema::CreateEnrollmentValues < BaseInputObject
    description 'HMIS Enrollment creation input'

    argument :project_id, ID, required: true
    argument :start_date, String, 'Start date with format yyyy-mm-dd', required: true
    argument :household_members, [HmisSchema::EnrollmentHouseholdMemberInput], required: true
    argument :in_progress, Boolean, required: false

    def to_enrollments_params
      result = []
      household_id = SecureRandom.uuid.gsub(/-/, '')

      household_members.each do |household_member|
        result << {
          personal_id: household_member.id,
          relationship_to_ho_h: household_member.relationship_to_ho_h,
          entry_date: start_date,
          project_id: project_id,
          household_id: household_id,
          in_progress: in_progress,
        }
      end

      result
    end
  end
end
