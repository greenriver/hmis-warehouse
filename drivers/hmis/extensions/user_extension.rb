# frozen_string_literal: true

module Hmis
  module UserExtension
    extend ActiveSupport::Concern

    included do
      # prefer after_commit over after_save, since the triggering change was to the User table in the App database,
      # but sync_to_hud_users makes changes in the Warehouse database
      after_commit :sync_to_hud_users, on: [:create, :update]
    end

    # Sync changes from the application user to matching HUD User records in HMIS data sources.
    # Only HMIS-owned HUD users are updated, since imported users are overwritten on import.
    def sync_to_hud_users
      return unless HmisEnforcement.hmis_enabled?
      return unless saved_change_to_email? || saved_change_to_first_name? || saved_change_to_last_name?

      previous_email = email_before_last_save if saved_change_to_email?

      hmis_data_source_ids = ::GrdaWarehouse::DataSource.hmis.pluck(:id)
      return unless hmis_data_source_ids.any?

      emails_to_match = [previous_email, email].compact.map(&:downcase)
      user_scope = Hmis::Hud::User.where(data_source_id: hmis_data_source_ids).where(user_email: emails_to_match)

      user_scope.each do |hud_user|
        hud_user.update!( # Update users individually, so PaperTrail tracks versions
          user_email: email.downcase,
          user_first_name: first_name,
          user_last_name: last_name,
        )
      end
    end
  end
end
