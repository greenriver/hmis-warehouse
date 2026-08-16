###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # Adopts an IdP-side email change after login by reading the account back through the connector's
  # management API.
  class SyncUserFromIdpJob < BaseJob
    queue_as ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)

    COOLDOWN_TTL = 5.minutes

    def perform(user_id:)
      user = User.find_by(id: user_id)
      return unless user
      return unless user.email_change_enabled?

      previous_email = reconcile(user)
      return if previous_email.blank?

      Rails.logger.info("Adopted IdP email for user #{user.id} (was #{previous_email})")
    rescue Idp::ServiceError => e
      # Stops a broken connector collecting a job per sign-in. This user's retry still runs.
      self.class.pause_connector!(user&.last_connector_id)
      raise e
    end

    # One retry covers a blip. Further attempts just duplicate the Sentry event.
    def calculated_attempts
      [0, Delayed::Worker.max_attempts - 2].max
    end

    # A re-run is a get_user that no-ops when the address hasn't moved.
    def self.supports_idempotent_retry?
      true
    end

    def self.connector_paused?(connector_id)
      return false if connector_id.blank?

      Rails.cache.exist?(cooldown_key(connector_id))
    end

    def self.pause_connector!(connector_id)
      return if connector_id.blank?

      Rails.cache.write(cooldown_key(connector_id), true, expires_in: COOLDOWN_TTL)
    end

    def self.cooldown_key(connector_id)
      "idp_sync_cooldown:#{connector_id}"
    end

    private

    # Two databases, no shared commit, so nested rather than atomic: a failed HUD sync rolls back the
    # adopted address.
    def reconcile(user)
      previous_email = nil
      GrdaWarehouseBase.transaction do
        user.transaction do
          previous_email = user.idp_reconcile_email!
          user.sync_to_hud_users(previous_email: previous_email) if previous_email.present? && HmisEnforcement.hmis_enabled?
        end
      end
      previous_email
    rescue ActiveRecord::RecordInvalid => e
      # A no-retry failure (e.g. the address already belongs to another user). Report and stop.
      Sentry.capture_exception_with_info(e, "Couldn't adopt IdP email for user #{user.id}", { user_id: user.id })
      nil
    rescue Idp::ServiceError => e
      # #perform owns the cooldown. Non-transient means the same answer comes back, so don't retry.
      raise e if e.transient?

      Sentry.capture_exception_with_info(e, "Couldn't adopt IdP email for user #{user.id}: #{e.message}")
      nil
    end
  end
end
