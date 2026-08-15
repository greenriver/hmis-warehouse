###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # Adopts an IdP-side profile change after login, through whichever channel the connector has
  # (Idp::Service#profile_source). Idp::JwtAuthentication#idp_schedule_user_sync enqueues one of
  # these per session.
  class SyncUserFromIdpJob < BaseJob
    queue_as ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)

    COOLDOWN_TTL = 5.minutes

    # @param claims [Hash, nil] the token's profile claims, supplied only for the :token_claims arm
    def perform(user_id:, claims: nil)
      user = User.find_by(id: user_id)
      return unless user

      case user.profile_source
      when :admin_api then sync_from_admin_api(user)
      when :token_claims then sync_from_claims(user, claims)
      end
    end

    # One retry covers a blip. Further attempts just duplicate the Sentry event.
    def calculated_attempts
      [0, Delayed::Worker.max_attempts - 2].max
    end

    # A re-run re-reads the same source and no-ops when nothing has moved.
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

    def sync_from_admin_api(user)
      # Nothing can have moved on a realm that offers no email self-service, so skip the Admin API read.
      return unless user.email_change_enabled?

      previous_email = reconcile(user)
      return if previous_email.blank?

      Rails.logger.info("Adopted IdP email for user #{user.id} (was #{previous_email})")
    rescue Idp::ServiceError => e
      # Stops a broken connector collecting a job per sign-in. This user's retry still runs.
      self.class.pause_connector!(user&.last_connector_id)
      raise e
    end

    # The claims arrived with the job, so this arm makes no IdP call — hence no Idp::ServiceError to
    # rescue and no connector cooldown to spend.
    def sync_from_claims(user, claims)
      return if claims.blank?

      result = reconcile_from_claims(user, claims.symbolize_keys)
      return if result.nil?

      moved = result[:previous_email].present? ? "email was #{result[:previous_email]}" : 'name only'
      Rails.logger.info("Adopted IdP profile claims for user #{user.id} (#{moved})")
    end

    # Same two-database nesting as #reconcile, for the same reason.
    def reconcile_from_claims(user, claims)
      result = nil
      GrdaWarehouseBase.transaction do
        user.transaction do
          result = user.idp_reconcile_profile_from_claims!(
            email: claims[:email],
            email_verified: claims[:email_verified],
            first_name: claims[:first_name],
            last_name: claims[:last_name],
          )
          # Called for a name-only change too, not just an address change: sync_to_hud_users pushes
          # first/last name alongside the address, and matches HUD rows on the current email when
          # previous_email is nil.
          user.sync_to_hud_users(previous_email: result[:previous_email]) if result && HmisEnforcement.hmis_enabled?
        end
      end
      result
    rescue ActiveRecord::RecordInvalid => e
      # The claimed address is taken here, or malformed. No retry fixes that.
      Sentry.capture_exception_with_info(
        e,
        "Couldn't adopt IdP profile claims for user #{user.id}",
        {
          user_id: user.id,
          attempted_email: user.email, # rolled back, but still dirty in memory
          retained_email: user.email_was,
          invalid_record: e.record.class.name,
          reason: e.record.errors.full_messages.join(', '),
        },
      )
      nil
    end

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
      # The new address is taken here, or malformed. No retry fixes that.
      Sentry.capture_exception_with_info(
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
      nil
    rescue Idp::ServiceError => e
      # #perform owns the cooldown. Non-transient means the same answer comes back, so don't retry.
      raise e if e.transient?

      Sentry.capture_exception_with_info(e, "Couldn't adopt IdP email for user #{user.id}: #{e.message}")
      nil
    end
  end
end
