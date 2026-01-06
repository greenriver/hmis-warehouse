###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Health
  class AgencyUserLookup
    class << self
      def build_cache
        # Cache the lookup hash in RequestStore for reuse within this request
        cache = build_lookup_hash
        RequestStore.store[:agency_user_lookup_cache] = cache if request_store_available?
        cache
      end

      def user_ids_for_agency(agency_id)
        cache = if request_store_available? && RequestStore.store[:agency_user_lookup_cache].present?
          RequestStore.store[:agency_user_lookup_cache]
        else
          build_lookup_hash
        end
        cache[:by_agency][agency_id] || []
      end

      private

      def request_store_available?
        defined?(RequestStore) && RequestStore.store.is_a?(Hash)
      end

      def build_lookup_hash
        active_user_ids = User.active.pluck(:id)

        # Single query to get all agency users for active users
        agency_users = Health::AgencyUser.where(user_id: active_user_ids)

        # Build hash: { agency_id => [user_id1, user_id2, ...] }
        lookup_hash = agency_users.each_with_object({}) do |au, hash|
          hash[au.agency_id] ||= []
          hash[au.agency_id] << au.user_id
        end

        {
          user_ids: active_user_ids,
          by_agency: lookup_hash,
        }
      end
    end
  end
end
