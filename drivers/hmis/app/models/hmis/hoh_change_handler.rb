###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis
  #
  # The HohChangeHandler class is responsible for handling changes to the Head of Household (HoH) in a household enrollment.
  # It provides methods to perform the change, apply the changes to the database, and validate the changes.
  #
  # This logic is split out from the UpdateRelationshipToHoH mutation in case we need to use it in cleanup routines,
  # for example bulk assigning HoH to the oldest adult in a household.
  #
  # Parameters:
  # - new_hoh_enrollment: The Enrollment that is becoming the Head of Household
  # - hud_user_id: The "UserID" of the HUD user making the change.
  class HohChangeHandler
    attr_accessor :new_hoh_enrollment, :household_enrollments, :old_hoh_enrollments, :new_hoh_move_in_date, :old_hoh_move_in_date, :validation_errors, :hud_user_id

    def initialize(new_hoh_enrollment:, hud_user_id:)
      self.new_hoh_enrollment = new_hoh_enrollment
      self.hud_user_id = hud_user_id

      # All Enrollments in the household (including new and old HoHs)
      self.household_enrollments = new_hoh_enrollment.household_members.preload(:client)
      # Previous HoHs (should only be one, but we handle multiple for data cleanup)
      self.old_hoh_enrollments = household_enrollments.
        filter(&:head_of_household?).
        sort_by { |en| [en.DateCreated, en.id] }

      self.old_hoh_move_in_date = old_hoh_enrollments.map(&:move_in_date).compact.first
      # Determine Move-in Date to transfer to new HoH, if applicable
      # TODO(#6857) For now, we don't transfer it if transferring it would lead it to being invalid. We plan to adjust this pending guidance from HUD.
      self.new_hoh_move_in_date = old_hoh_move_in_date if old_hoh_move_in_date && old_hoh_move_in_date >= new_hoh_enrollment.entry_date
      # self.new_hoh_move_in_date = [old_hoh_move_in_date, new_hoh_enrollment.entry_date].max if old_hoh_move_in_date
      self.validation_errors = HmisErrors::Errors.new
    end

    def validate(include_warnings: true)
      return validation_errors unless include_warnings # there are no hard-stop validations at this time, to allow for data correction in tricky situations

      old_hoh = old_hoh_enrollments.first&.client
      # Add generic message indicating that HoH will change from X to Y
      add_warning(self.class.change_hoh_message(old_hoh, new_hoh_enrollment.client))

      # Add informational message about Move-in Date transferring from old HoH to new HoH
      add_warning(self.class.move_in_date_transfer_msg(new_hoh_move_in_date)) if new_hoh_move_in_date

      # Add warning if Move-in Date won't transfer because new HoH entered after move-in
      add_warning(self.class.move_in_date_not_transfered_msg(old_hoh_move_in_date)) if old_hoh_move_in_date && !new_hoh_move_in_date

      # HoH shouldn't be WIP, unless all members are WIP
      add_warning(self.class.incomplete_hoh_message) if new_hoh_enrollment.in_progress? && household_enrollments.not_in_progress.exists?

      # HoH shouldn't be Exited, unless all clients are Exited
      add_warning(self.class.exited_hoh_message) if new_hoh_enrollment.exit.present? && household_enrollments.open_on_date(Date.tomorrow).exists?

      # HoH shouldn't be a child, unless all members are children
      new_hoh_age = new_hoh_enrollment.client.age
      add_warning(self.class.child_hoh_message) if new_hoh_age.present? && new_hoh_age < 18 && household_enrollments.find(&:adult?)

      validation_errors
    end

    # Caller should run this is in a transaction, as it changes multiple records
    def apply_changes!
      # Apply changes to household members first, then the HoH
      household_enrollments.each do |hhm|
        next if hhm.id == new_hoh_enrollment.id

        # Clear Move-in Date on non-HoH members.
        # TODO(#6857) For now, we leave the old MID as-is IF we were unable to transfer it because the new HoH entered after move-in. We plan to adjust this pending guidance from HUD.
        hhm.move_in_date = nil unless hhm.head_of_household? && hhm.move_in_date && !new_hoh_move_in_date

        # Update RelationshipToHoH on previous HoH
        if hhm.head_of_household?
          hhm.relationship_to_ho_h = infer_relationship_to_new_hoh(new_hoh_enrollment)
          # Move-in Address(es) from old HoH should transfer to new HoH. We only expect 1, but it's OK if there are more.
          hhm.move_in_addresses.each { |addr| addr.update!(enrollment: new_hoh_enrollment) }
        end

        if hhm.changed?
          hhm.user_id = hud_user_id # set user who last touched the record
          hhm.save!
        end
      end

      new_hoh_enrollment.relationship_to_ho_h = 1
      new_hoh_enrollment.move_in_date = new_hoh_move_in_date if new_hoh_move_in_date
      new_hoh_enrollment.user_id = hud_user_id
      new_hoh_enrollment.save!
    end

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

    def self.move_in_date_transfer_msg(move_in_date)
      "Move-in Date #{move_in_date.strftime('%m/%d/%Y')} will be transferred to the new HoH."
    end

    def self.move_in_date_not_transfered_msg(move_in_date)
      # TODO(#6857) When we adjust the behavior, we should change this message to communicate how/why the Move-in date was changed.
      "Move-in Date #{move_in_date.strftime('%m/%d/%Y')} will not be transferred to the new HoH, because they entered after Move-in. Please adjust the Move-in Date on the new HoH as needed."
    end

    private

    def add_warning(full_message)
      validation_errors.add(:enrollment, :informational, severity: :warning, full_message: full_message)
    end

    # infer which relationship the previous HoH should have to the new HoH
    def infer_relationship_to_new_hoh(new_hoh)
      case new_hoh.relationship_to_ho_h
      when 3 # Spouse
        3 # Spouse
      when 4 # Other relative
        4 # Other relative
      when 5 # Unrelated household member
        5 # Unrelated household member
      when 2 # Child
        4 # Other relative a.k.a. parent. This is unexpected, because child shouldn't become HoH.
      else
        6 # Unrelated household member
      end
    end
  end
end
