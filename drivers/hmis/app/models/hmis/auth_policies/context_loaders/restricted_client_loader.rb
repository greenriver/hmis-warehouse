###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Loads which clients are marked as restricted, in bulk.
#
# Only restricted clients have a row in hmis_restricted_records, so any client that has been loaded
# but isn't in the cache is unrestricted.
#
# See docs/features/hmis/hmis-restricted-records.md
module Hmis::AuthPolicies::ContextLoaders
  class RestrictedClientLoader
    def initialize
      @restricted_client_ids = Set.new
      @loaded_client_ids = Set.new
    end

    def restricted?(client_id)
      preload([client_id])
      @restricted_client_ids.include?(client_id)
    end

    def preload(client_ids)
      new_client_ids = client_ids.compact.uniq - @loaded_client_ids.to_a
      return if new_client_ids.empty?

      @loaded_client_ids.merge(new_client_ids)
      @restricted_client_ids.merge(
        Hmis::RestrictedRecord.for_clients.where(restrictable_id: new_client_ids).pluck(:restrictable_id),
      )
    end

    # Restriction can change mid-request, when a user marks or unmarks a client.
    def clear_cache!
      @restricted_client_ids.clear
      @loaded_client_ids.clear
    end
  end
end
