###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Loads and caches data source IDs for clients. Used as a secondary guard
# to ensure users only access records in their current HMIS session.
module Hmis::AuthPolicies::ContextLoaders
  class ClientDataSourceLoader
    def initialize
      # {client_id => data_source_id, ...}
      @cache = {}
    end

    def get(client_id)
      return nil unless client_id

      preload([client_id]) unless @cache.key?(client_id)
      @cache[client_id]
    end

    def preload(client_ids)
      return if client_ids.empty?

      new_client_ids = client_ids.uniq.compact - @cache.keys
      return if new_client_ids.empty?

      results = hmis_clients_scope.where(id: new_client_ids).pluck(:id, :data_source_id).to_h
      @cache.merge!(results)

      # For clients that don't exist in any HMIS data source, add `nil` to the cache so we don't check the db again
      no_client_ids = new_client_ids - results.keys
      @cache.merge!(no_client_ids.index_with(nil))
    end

    private

    def hmis_clients_scope
      Hmis::Hud::Client.hmis
    end
  end
end
