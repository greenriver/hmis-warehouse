module Mutations
  class SetHoHForEnrollment < BaseMutation
    argument :household_id, ID, required: true
    argument :client_id, ID, required: true

    field :enrollment, Types::HmisSchema::Enrollment, null: true

    def resolve(household_id:, client_id:)
      errors = []
      enrollment = nil

      client = Hmis::Hud::Client.find_by(id: client_id)

      if client
        household_enrollments = Hmis::Hud::Enrollment.editable_by(current_user).where(household_id: household_id)
        new_hoh_enrollment = household_enrollments.find_by(personal_id: client&.personal_id)
        if new_hoh_enrollment
          update_params = { user_id: hmis_user.user_id }
          household_enrollments.where(relationship_to_ho_h: 1).update_all(relationship_to_ho_h: 99, **update_params)
          new_hoh_enrollment.update(relationship_to_ho_h: 1, **update_params)
          new_hoh_enrollment.save!

          enrollment = new_hoh_enrollment
        else
          errors << HmisErrors::Error.new(:household_id, full_message: "No enrollment for this client with household ID '#{household_id}'")
        end
      else
        errors << HmisErrors::Error.new(:client_id, :not_found)
      end

      {
        enrollment: enrollment,
        errors: errors,
      }
    end
  end
end
