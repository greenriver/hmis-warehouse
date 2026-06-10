# frozen_string_literal: true

module Hmis
  module UserExtension
    extend ActiveSupport::Concern

    # Sync changes from the application user to matching HUD User records in HMIS data sources.
    # Only HMIS-owned HUD users are updated, since imported users are overwritten on import.
    def sync_to_hud_users(previous_email: nil)
      return unless HmisEnforcement.hmis_enabled?

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
