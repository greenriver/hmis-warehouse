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
      self.new_hoh_move_in_date = [old_hoh_move_in_date, new_hoh_enrollment.entry_date].max if old_hoh_move_in_date
      self.validation_errors = HmisErrors::Errors.new
    end

    def validate(include_warnings: true)
      return validation_errors unless include_warnings # there are no hard-stop validations at this time, to allow for data correction in tricky situations

      old_hoh = old_hoh_enrollments.first&.client
      # Add generic message indicating that HoH will change from X to Y
      add_warning(self.class.change_hoh_message(old_hoh, new_hoh_enrollment.client))

      # Add message about Move-in Date, only if the household Move-in Date is changing (which would occur if the new HoH entered after move-in)
      add_warning(self.class.move_in_date_change_msg(old_hoh_move_in_date, new_hoh_move_in_date)) if new_hoh_move_in_date && new_hoh_move_in_date != old_hoh_move_in_date

      # HoH shouldn't be WIP, unless all members are WIP
      add_warning(self.class.incomplete_hoh_message) if new_hoh_enrollment.in_progress? && household_enrollments.not_in_progress.exists?

      # HoH shouldn't be Exited, unless all clients are Exited
      add_warning(self.class.exited_hoh_message) if new_hoh_enrollment.exit.present? && household_enrollments.open_on_date(Date.tomorrow).exists?

      # HoH shouldn't be a child, unless all members are children
      new_hoh_age = new_hoh_enrollment.client.age
      add_warning(self.class.child_hoh_message) if new_hoh_age.present? && new_hoh_age < 18 && household_enrollments.find(&:adult?)

      validation_errors
    end

    def apply_changes!
      Hmis::Hud::Enrollment.transaction do
        # Apply changes to household members first, then the HoH
        household_enrollments.each do |hhm|
          next if hhm.id == new_hoh_enrollment.id

          # Clear RelationshipToHoH on previous HoH
          if hhm.relationship_to_ho_h == 1
            hhm.relationship_to_ho_h = 99
            # Move-in Address(es) from old HoH should transfer to new HoH. We only expect 1, but it's OK if there are more.
            hhm.move_in_addresses.each { |addr| addr.update!(enrollment: new_hoh_enrollment) }
          end

          # Clear Move-in Date on non-HoH members
          hhm.move_in_date = nil

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

    def self.move_in_date_change_msg(old_hoh_move_in_date, new_hoh_move_in_date)
      "Move-in Date will change from #{old_hoh_move_in_date.strftime('%m/%d/%Y')} to #{new_hoh_move_in_date.strftime('%m/%d/%Y')}, because the new Head of Household entered after the household moved in."
    end

    private

    def add_warning(full_message)
      validation_errors.add(:enrollment, :informational, severity: :warning, full_message: full_message)
    end
  end
end
