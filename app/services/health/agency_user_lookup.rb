###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Health
  class AgencyUserLookup
    def self.build_cache
      return if RequestStore.store[:agency_user_lookup_cache].present?

      active_user_ids = User.active.pluck(:id)

      # Single query to get all agency users for active users
      agency_users = Health::AgencyUser.where(user_id: active_user_ids)

      # Build hash: { agency_id => [user_id1, user_id2, ...] }
      lookup_hash = agency_users.each_with_object({}) do |au, hash|
        hash[au.agency_id] ||= []
        hash[au.agency_id] << au.user_id
      end

      RequestStore.store[:agency_user_lookup_cache] = {
        user_ids: active_user_ids,
        by_agency: lookup_hash,
      }
    end

    def self.user_ids_for_agency(agency_id)
      build_cache
      RequestStore.store[:agency_user_lookup_cache][:by_agency][agency_id] || []
    end
  end
end
