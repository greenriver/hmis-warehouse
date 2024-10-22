###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class UpdateRelationshipToHoH < BaseMutation
    argument :enrollment_id, ID, required: true
    argument :enrollment_lock_version, Integer, required: false
    argument :relationship_to_ho_h, Types::HmisSchema::Enums::Hud::RelationshipToHoH, required: true
    argument :confirmed, Boolean, 'Whether user has confirmed the action', required: false

    field :enrollment, Types::HmisSchema::Enrollment, null: true

    def resolve(enrollment_id:, enrollment_lock_version: nil, relationship_to_ho_h:, confirmed: false)
      enrollment = Hmis::Hud::Enrollment.viewable_by(current_user).find_by(id: enrollment_id)
      access_denied! unless enrollment && current_user.permissions_for?(enrollment, :can_edit_enrollments)

      enrollment.lock_version = enrollment_lock_version if enrollment_lock_version

      if relationship_to_ho_h == 1
        Hmis::Hud::Enrollment.transaction do
          # Lock to avoid duplicate request collisions
          enrollment.household_members.lock!

          hoh_changer = Hmis::HohChangeHandler.new(new_hoh_enrollment: enrollment, hud_user_id: hmis_user.user_id)
          validations = hoh_changer.validate(include_warnings: !confirmed)
          return { errors: validations } if validations.any?

          hoh_changer.apply_changes!
        end
      else
        # Set new relationship value
        enrollment.relationship_to_ho_h = relationship_to_ho_h
        # Set user HUD that most recently touched the record
        enrollment.user_id = hmis_user.user_id
        enrollment.save!
      end

      { enrollment: enrollment }
    end
  end
end
