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

    def self.incomplete_hoh_message
      'Selected HoH has an incomplete enrollment.'
    end

    def self.exited_hoh_message
      'Selected HoH is exited.'
    end

    def self.child_hoh_message
      'Selected HoH is a child.'
    end

    def self.change_hoh_message(old_hoh, new_hoh)
      old_hoh_name = old_hoh&.brief_name
      new_hoh_name = new_hoh&.brief_name
      if old_hoh_name.present?
        "Head of Household will change from #{old_hoh_name} to #{new_hoh_name}."
      else
        "#{new_hoh_name} will be the Head of Household."
      end
    end

    def resolve(enrollment_id:, enrollment_lock_version: nil, relationship_to_ho_h:, confirmed: false)
      enrollment = Hmis::Hud::Enrollment.viewable_by(current_user).find_by(id: enrollment_id)
      raise 'Not found' unless enrollment.present?
      raise 'Access denied' unless current_user.permissions_for?(enrollment, :can_edit_enrollments)

      enrollment.lock_version = enrollment_lock_version if enrollment_lock_version

      errors = HmisErrors::Errors.new
      is_hoh_change = relationship_to_ho_h == 1
      if is_hoh_change
        household_enrollments = enrollment.household_members.preload(:client)
        # Give an informational warning about the HoH change.
        unless confirmed
          old_hoh = household_enrollments.where(relationship_to_ho_h: 1).first&.client
          full_message = self.class.change_hoh_message(old_hoh, enrollment.client)
          errors.add :enrollment, :informational, severity: :warning, full_message: full_message
        end

        # HoH shouldn't be WIP, unless all members are WIP
        errors.add :enrollment, :informational, severity: :warning, full_message: self.class.incomplete_hoh_message if enrollment.in_progress? && household_enrollments.not_in_progress.exists?
        # HoH shouldn't be Exited, unless all clients are Exited
        errors.add :enrollment, :informational, severity: :warning, full_message: self.class.exited_hoh_message if enrollment.exit.present? && household_enrollments.open_on_date(Date.tomorrow).exists?
        # HoH shouldn't be a child, unless all members are children
        new_hoh_age = enrollment.client.age
        errors.add :enrollment, :informational, severity: :warning, full_message: self.class.child_hoh_message if new_hoh_age.present? && new_hoh_age < 18 && household_enrollments.find(&:adult?)
      end

      errors.drop_warnings! if confirmed
      return { errors: errors } if errors.any?

      # Set new relationship value
      enrollment.relationship_to_ho_h = relationship_to_ho_h
      # Set user HUD that most recently touched the record
      enrollment.user_id = hmis_user.user_id

      # Return if there are any AR errors (not expected)
      unless enrollment.valid?
        errors.add_ar_errors(enrollment.errors&.errors)
        return { errors: errors }
      end

      # Save changes in a transaction.
      # If this is a HoH change, give old HoH(s) a 99 relationship value.
      Hmis::Hud::Enrollment.transaction do
        if is_hoh_change
          household_enrollments.filter(&:head_of_household?).each do |old_hoh_enrollment|
            next if old_hoh_enrollment.id == enrollment.id

            old_hoh_enrollment.relationship_to_ho_h = 99
            old_hoh_enrollment.user_id = hmis_user.user_id
            old_hoh_enrollment.save!
          end
        end

        enrollment.save!
      end

      { enrollment: enrollment }
    end
  end
end
