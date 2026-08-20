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
      # IDs known to be restricted. Absence is only meaningful for IDs also in @loaded_client_ids.
      @restricted_client_ids = Set.new
      # IDs whose restriction status has been resolved. An ID here but not in @restricted_client_ids is unrestricted.
      @loaded_client_ids = Set.new
      # Memo of data_source_id => [restricted client ids] for #restricted_ids_in_data_source.
      @ids_by_data_source = {}
    end

    def restricted?(client_id)
      preload([client_id])
      @restricted_client_ids.include?(client_id)
    end

    # Every restricted client ID in the data source. Restriction is expected to be relatively rare, so
    # loading them all at once is acceptable; used to omit them from client search.
    def restricted_ids_in_data_source(data_source_id)
      @ids_by_data_source[data_source_id] ||= begin
        ids = Hmis::RestrictedRecord.for_clients.where(data_source_id: data_source_id).pluck(:restrictable_id)
        # Known restricted, so record them rather than re-querying one page of clients at a time
        @loaded_client_ids.merge(ids)
        @restricted_client_ids.merge(ids)
        ids
      end
    end

    def preload(client_ids)
      new_client_ids = client_ids.compact.uniq.reject { |id| @loaded_client_ids.include?(id) }
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
      @ids_by_data_source.clear
    end
  end
end
