###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # Adopt an IdP-side email change after the user authenticates. The JWT can't report one:
  # oauth2-proxy still holds a token minted before the change (see Idp::Support#idp_reconcile_email!).
  # Enqueued from Idp::JwtAuthentication#idp_schedule_user_sync.
  class SyncUserFromIdpJob < BaseJob
    queue_as ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)

    COOLDOWN_TTL = 5.minutes

    def perform(user_id:)
      user = User.find_by(id: user_id)
      return unless user
      # Same gate as the Email tab's reconciliation; false for a service that won't build.
      return unless user.email_change_enabled?

      previous_email = reconcile(user)
      return if previous_email.blank?

      Idp::EmailChangePending.clear!(user)
      Rails.logger.info("Adopted IdP email for user #{user.id} (was #{previous_email})")
    rescue Idp::ServiceError => e
      # Keep a broken connector from collecting a failing job per sign-in. This user's retry still runs.
      self.class.pause_connector!(user&.last_connector_id)
      raise e
    end

    # One retry covers a blip. sentry-delayed_job reports every failure, so further attempts only
    # duplicate the event.
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

    # Two databases with no shared commit, so nested rather than atomic: a failed HUD sync unwinds
    # the adopted address. Same shape as Idp::AccountEmailsController#reconcile_email_from_idp.
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
      # The IdP moved the address but we can't store it — taken here, or malformed. No retry fixes
      # that, so report it and stop.
      stand_down(
        user,
        e,
        "Couldn't adopt IdP email for user #{user.id}",
        {
          user_id: user.id,
          attempted_email: user.email, # rolled back, but still dirty in memory
          retained_email: user.email_was,
          invalid_record: e.record.class.name,
          reason: e.record.errors.full_messages.join(', '),
        },
      )
    rescue Idp::ServiceError => e
      # A connector fault is #perform's to start the cooldown on. Non-transient means the IdP answered
      # fine and will keep saying the same thing, so there's nothing to retry.
      raise e if e.transient?

      stand_down(user, e, "Couldn't adopt IdP email for user #{user.id}: #{e.message}")
    end

    # Report once and drop the pending marker. Nothing here resolves on its own, so leaving the marker
    # set would just repeat it every minute for the day it holds.
    def stand_down(user, error, message, context = {})
      Idp::EmailChangePending.clear!(user)
      Sentry.capture_exception_with_info(error, message, context)
      nil
    end
  end
end
