###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class UpdateRelationshipToHoH < BaseMutation
    argument :id, ID, required: true
    argument :relationship_to_ho_h, Types::HmisSchema::Enums::Hud::RelationshipToHoH, required: true
    argument :confirmed, Boolean, required: false

    field :enrollment, Types::HmisSchema::Enrollment, null: true

    def resolve(id:, relationship_to_ho_h:, confirmed: false)
      enrollment = Hmis::Hud::Enrollment.viewable_by(current_user).find_by(id: id)

      errors = HmisErrors::Errors.new
      errors.add :enrollment, :not_found unless enrollment.present?
      return { errors: errors } if errors.any?

      errors.add :enrollment, :not_allowed unless current_user.permissions_for?(enrollment, :can_edit_enrollments)
      return { errors: errors } if errors.any?

      is_hoh_change = relationship_to_ho_h == 1
      if is_hoh_change
        household_enrollments = enrollment.household_members
        # WIP member cannot be HoH, unless all members are WIP
        errors.add :client_id, :invalid, full_message: 'Selected member cannot be the Head of Household because their enrollment is incomplete.' if enrollment.in_progress? && household_enrollments.not_in_progress.exists?
        # Exited member cannot be HoH, unless all members are exited
        errors.add :client_id, :invalid, full_message: 'Exited member cannot be the Head of Household.' if enrollment.exit.present? && household_enrollments.open_on_date(Date.tomorrow).exists?

        # TODO add child warning, make the above exited one a warnings
      end

      errors.reject!(&:warning?) if confirmed
      return { errors: errors } if errors.any?

      update_params = { user_id: hmis_user.user_id }
      Hmis::Hud::Enrollment.transaction do
        household_enrollments.where(relationship_to_ho_h: 1).update_all(relationship_to_ho_h: 99, **update_params) if is_hoh_change
        enrollment.update(relationship_to_ho_h: relationship_to_ho_h, **update_params)
        enrollment.touch
      end

      errors = []
      unless enrollment.valid?
        errors << enrollment.errors.errors
        enrollment = nil
      end

      {
        enrollment: enrollment,
        errors: errors,
      }
    end
  end
end
