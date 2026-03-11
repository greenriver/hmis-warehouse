# frozen_string_literal: true

module Hmis
  module UserExtension
    extend ActiveSupport::Concern

    included do
      # prefer after_commit over after_save, since the triggering change was to the User table in the App database,
      # but sync_to_hud_users makes changes in the Warehouse database
      after_commit :sync_to_hud_users, on: [:create, :update]
    end

    private

    def sync_to_hud_users
      return unless saved_change_to_email? || saved_change_to_first_name? || saved_change_to_last_name?

      previous_email = email_before_last_save if saved_change_to_email?
      Hmis::SyncAppUserToHudUsers.call(self, previous_email: previous_email)
    end
  end
end
