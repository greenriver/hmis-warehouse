# frozen_string_literal: true

module Hmis::Ce
  # Resolves CE expression keys (same strings as match expressions / table column keys) to
  # current values via Hmis::Ce::Match::Expression::FieldMap, batched by destination client id.
  class ExpressionFieldValues
    MAX_KEYS = 50

    # @return [Hash{Integer => Hash{String => Object}}] outer keys are destination client ids
    def self.for_destination_clients(destination_client_ids:, keys:)
      ids = Array.wrap(destination_client_ids).filter_map { |raw| raw.presence&.to_i }.uniq
      return {} if ids.empty?

      keys = Array.wrap(keys).map(&:to_s).uniq.first(MAX_KEYS)

      # Create map to populate with values for each destination client
      # { destination_client_id => {} }
      destination_id_to_values = ids.index_with { |_id| {} }
      return destination_id_to_values if keys.empty?

      # Get clients to resolve expressions for
      clients = GrdaWarehouse::Hud::Client.where(id: ids)
      field_map = Hmis::Ce::Match::Expression::FieldMap.new

      # Resolve values for each key, and store in the destination_id_to_values map
      keys.each do |key|
        values = field_map.client_query(clients, key)
        ids.each do |id|
          destination_id_to_values[id][key] = values[id]
        end
      end

      destination_id_to_values
    end

    def self.merge_key!(accumulator:, destination_ids:, field_map:, clients:, key:)
      values = field_map.client_query(clients, key)
      destination_ids.each do |id|
        accumulator[id][key] = values[id]
      end
    end
  end
end
