###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # Marks that a user has started an email change at the IdP, so we look for the new address sooner
  # than the usual interval. A cache key rather than a column, since it only speeds up a read-back
  # that happens anyway — a flush degrades to the slower interval.
  class EmailChangePending
    # Long enough for a confirmation link clicked the next morning.
    TTL = 24.hours

    class << self
      def mark!(user)
        Rails.cache.write(key(user), true, expires_in: TTL)
      end

      def pending?(user)
        Rails.cache.exist?(key(user))
      end

      def clear!(user)
        Rails.cache.delete(key(user))
      end

      private def key(user)
        "idp_email_change_pending:#{user.id}"
      end
    end
  end
end
