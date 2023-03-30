module Mutations
  class SetHoHForEnrollment < BaseMutation
    argument :household_id, ID, required: true
    argument :client_id, ID, required: true

    field :enrollment, Types::HmisSchema::Enrollment, null: true

    def resolve(household_id:, client_id:)
      errors = HmisErrors::Errors.new
      client = Hmis::Hud::Client.find_by(id: client_id)

      errors.add :client_id, :not_found unless client.present?
      return { errors: errors } if errors.any?

      household_enrollments = Hmis::Hud::Enrollment.viewable_by(current_user).where(household_id: household_id)

      errors.add :household_id, :not_found unless household_enrollments.exists?
      return { errors: errors } if errors.any?

      errors.add :household_id, :not_allowed unless current_user.permissions_for?(household_enrollments.first, :can_edit_enrollments)
      return { errors: errors } if errors.any?

      new_hoh_enrollment = household_enrollments.find_by(personal_id: client.personal_id)

      errors.add :client_id, :invalid, full_message: "No enrollment for this client with household ID '#{household_id}'" unless new_hoh_enrollment.present?
      return { errors: errors } if errors.any?

      # WIP member cannot be HoH, unless all members are WIP
      errors.add :client_id, :invalid, full_message: 'Selected member cannot be the Head of Household because their enrollment is incomplete.' if new_hoh_enrollment.in_progress? && household_enrollments.not_in_progress.exists?
      # Exited member cannot be HoH, unless all members are exited
      errors.add :client_id, :invalid, full_message: 'Exited member cannot be the Head of Household.' if new_hoh_enrollment.exit.present? && household_enrollments.open_on_date(Date.tomorrow).exists?
      return { errors: errors } if errors.any?

      update_params = { user_id: hmis_user.user_id }
      Hmis::Hud::Enrollment.transaction do
        household_enrollments.where(relationship_to_ho_h: 1).update_all(relationship_to_ho_h: 99, **update_params)
        new_hoh_enrollment.update(relationship_to_ho_h: 1, **update_params)
        new_hoh_enrollment.save!
      end

      {
        enrollment: new_hoh_enrollment,
        errors: [],
      }
    end
  end
end
