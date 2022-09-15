module Mutations
  class SetHoHForEnrollment < BaseMutation
    argument :household_id, ID, required: true
    argument :client_id, ID, required: true

    field :enrollment, Types::HmisSchema::Enrollment, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(household_id:, client_id:)
      errors = []
      enrollment = nil

      client = Hmis::Hud::Client.find_by(id: client_id)

      if client
        household_enrollments = Hmis::Hud::Enrollment.viewable_by(current_user).where(household_id: household_id)
        new_hoh_enrollment = household_enrollments.find_by(personal_id: client&.personal_id)
        if new_hoh_enrollment
          household_enrollments.where(relationship_to_ho_h: 1).update_all(relationship_to_ho_h: 99)
          new_hoh_enrollment.relationship_to_ho_h = 1
          new_hoh_enrollment.save!

          enrollment = new_hoh_enrollment
        else
          errors << InputValidationError.new("No enrollment for this client with household ID '#{household_id}'", attribute: 'household_id')
        end
      else
        errors << InputValidationError.new("No client with id '#{client_id}'", attribute: 'client_id')
      end

      {
        enrollment: enrollment,
        errors: errors,
      }
    end
  end
end
