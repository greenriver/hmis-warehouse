# frozen_string_literal: true

module Hmis
  class SyncAppUserToHudUsers
    # Syncs changes to the application user with the corresponding HUD Users.
    # Syncs the first name, last name, and email fields.
    # Only touches HMIS HUD user records. Since other data sources are migrated-in, their User values get overwritten on import.
    # @param app_user [User] The application user that changed
    # @param previous_email [String, nil] The user's previous email, if changed, for matching to HUD User records
    def self.call(app_user, previous_email: nil)
      hmis_data_source_ids = ::GrdaWarehouse::DataSource.hmis.pluck(:id)
      emails_to_match = [previous_email, app_user.email].compact.map(&:downcase)
      user_scope = Hmis::Hud::User.where(data_source_id: hmis_data_source_ids).where(user_email: emails_to_match)

      user_scope.each do |hud_user|
        hud_user.update!( # Update users individually, so PaperTrail tracks versions
          user_email: app_user.email.downcase,
          user_first_name: app_user.first_name,
          user_last_name: app_user.last_name,
        )
      end
    end
  end
end
