###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Sources
  # Resolves CE expression keys (same strings as match expressions / table column keys) to
  # current values via Hmis::Ce::Match::Expression::FieldMap, batched by destination client id.
  class CeExpressionFieldValuesSource < GraphQL::Dataloader::Source
    MAX_KEYS = 50

    def initialize(keys:)
      @keys = Array.wrap(keys).map(&:to_s).uniq.first(MAX_KEYS)
    end

    # @return [Array<Hash{String => Object}}] of values for the given keys, one for each destination client id in the same order as the input
    def fetch(destination_client_ids)
      ids = Array.wrap(destination_client_ids).filter_map { |raw| raw.presence&.to_i }.uniq
      return [] if ids.empty?

      # Create map to populate with values for each destination client
      # { destination_client_id => {} }
      destination_id_to_values = ids.index_with { |_id| {} }
      return destination_id_to_values if @keys.empty?

      # Get clients to resolve expressions for
      clients = GrdaWarehouse::Hud::Client.where(id: ids)
      field_map = Hmis::Ce::Match::Expression::FieldMap.new

      # Resolve values for each key, and store in the destination_id_to_values map
      @keys.each do |key|
        values = field_map.client_query(clients, key)
        ids.each do |id|
          destination_id_to_values[id][key] = values[id]
        end
      end

      destination_id_to_values.values
    end

    def self.batch_key_for(*_batch_args, keys:)
      [Array.wrap(keys).map(&:to_s).sort]
    end
  end
end
