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

    def self.move_in_date_change_msg(old_hoh_move_in_date, new_hoh_move_in_date)
      "Move-in Date will change from #{old_hoh_move_in_date.strftime('%m/%d/%Y')} to #{new_hoh_move_in_date.strftime('%m/%d/%Y')}, because the new Head of Household entered after the household moved in."
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

        # Determine the Move-in Date for the new HoH. If the new HoH entered AFTER the household moved in,
        # then their move-in date should be their Entry Date.
        old_hoh_move_in_date = household_enrollments.filter(&:head_of_household?).map(&:move_in_date).compact.first
        new_hoh_move_in_date = [old_hoh_move_in_date, enrollment.entry_date].max if old_hoh_move_in_date

        # Give an informational warning about the HoH change.
        unless confirmed
          old_hoh = household_enrollments.where(relationship_to_ho_h: 1).first&.client
          full_message = self.class.change_hoh_message(old_hoh, enrollment.client)
          errors.add :enrollment, :informational, severity: :warning, full_message: full_message
          # Add message about Move-in Date only if the household Move-in Date is changing (which would occur if the new HoH entered after move-in)
          errors.add :enrollment, :informational, severity: :warning, full_message: self.class.move_in_date_change_msg(old_hoh_move_in_date, new_hoh_move_in_date) if new_hoh_move_in_date && new_hoh_move_in_date != old_hoh_move_in_date
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
      # Set Move-in Date on new HoH, if any
      # FIXME: MOVE-IN ADDRESS NEEDS TO MOVE TOO. pull to a new function handle_hoh_change(old_hohs,new_hoh,other_members)
      enrollment.move_in_date = new_hoh_move_in_date if new_hoh_move_in_date

      # Return if there are any AR errors (not expected)
      unless enrollment.valid?
        errors.add_ar_errors(enrollment.errors&.errors)
        return { errors: errors }
      end

      Hmis::Hud::Enrollment.transaction do
        # If this is a HoH change, we need to:
        # 1) Un-set previous HoH's by setting their RelationshipToHoH to 99
        # 2) Clear move-in dates on non-Hoh members
        # 3) If applicable, transfer Move-in Date from old HoH to new HoH
        if is_hoh_change
          household_enrollments.each do |hhm|
            next if hhm.id == enrollment.id # skip new hoh

            # Clear RelationshipToHoH on previous HoH
            hhm.relationship_to_ho_h = 99 if hhm.relationship_to_ho_h == 1

            # Clear Move-in Date on non-HoH members
            hhm.move_in_date = nil

            if hhm.changed?
              hhm.user_id = hmis_user.user_id # set user who lasted touched the record
              hhm.save!
            end
          end
        end

        enrollment.save!
      end

      { enrollment: enrollment }
    end
  end
end
