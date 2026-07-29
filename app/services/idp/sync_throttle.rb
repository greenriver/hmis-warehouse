###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # Bounds how often an authenticated request re-reads the account from the IdP. A reservation rather
  # than a marker: whether you took it is what decides if this request does the read.
  class SyncThrottle
    # Bounds how long an IdP-side email change goes unnoticed here.
    INTERVAL = 30.minutes

    # Used while a change is in flight, so the new address lands on about the next page load.
    PENDING_INTERVAL = 1.minute

    class << self
      # False when another request already holds the reservation. unless_exist is atomic, so
      # concurrent requests claim once.
      def claim!(user, pending:)
        ttl = pending ? PENDING_INTERVAL : INTERVAL
        Rails.cache.write(key(user), true, unless_exist: true, expires_in: ttl)
      end

      def release!(user)
        Rails.cache.delete(key(user))
      end

      def held?(user)
        Rails.cache.exist?(key(user))
      end

      private def key(user)
        "idp_sync:#{user.id}"
      end
    end
  end
end
