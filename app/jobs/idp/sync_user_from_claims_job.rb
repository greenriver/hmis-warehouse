###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # Adopts the profile from a JWT. Used for when we have no admin API to the IdP
  # to keep user profiles in sync
  class SyncUserFromClaimsJob < BaseJob
    queue_as ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)

    def perform(user_id:, claims:)
      user = User.find_by(id: user_id)
      return unless user

      result = reconcile(user, claims.symbolize_keys)
      return if result.nil?

      moved = result[:previous_email].present? ? "email was #{result[:previous_email]}" : 'name only'
      Rails.logger.info("Adopted IdP profile claims for user #{user.id} (#{moved})")
    end

    private

    def reconcile(user, claims)
      result = nil
      GrdaWarehouseBase.transaction do
        user.transaction do
          result = user.idp_reconcile_profile_from_claims!(
            email: claims[:email],
            email_verified: claims[:email_verified],
            first_name: claims[:first_name],
            last_name: claims[:last_name],
          )
          user.sync_to_hud_users(previous_email: result[:previous_email]) if result && HmisEnforcement.hmis_enabled?
        end
      end
      result
    rescue ActiveRecord::RecordInvalid => e
      # e.g. the claimed address already belongs to another user. Report and stop.
      Sentry.capture_exception_with_info(e, "Couldn't adopt IdP profile claims for user #{user.id}", { user_id: user.id })
      nil
    end
  end
end
