# frozen_string_literal: true

module Hmis::Ce
  # Resolves CE expression keys (same strings as match expressions / table column keys) to
  # current values via Hmis::Ce::Match::Expression::FieldMap, batched by destination client id.
  class ExpressionFieldValues
    MAX_KEYS = 50

    def self.slice(destination_client_id:, keys:, current_date: Date.current)
      id = destination_client_id.to_i
      for_destination_clients(destination_client_ids: [id], keys: keys, current_date: current_date)[id] || {}
    end

    # @return [Hash{Integer => Hash{String => Object}}] outer keys are destination client ids
    def self.for_destination_clients(destination_client_ids:, keys:, current_date: Date.current)
      ids = Array.wrap(destination_client_ids).filter_map { |raw| raw.presence&.to_i }.uniq
      return {} if ids.empty?

      keys = normalize_keys(keys)
      by_id = ids.index_with { |_id| {} }
      return by_id if keys.empty?

      clients = GrdaWarehouse::Hud::Client.where(id: ids)
      field_map = Hmis::Ce::Match::Expression::FieldMap.new(current_date: current_date)

      keys.each do |key|
        merge_key!(by_id, ids, field_map, clients, key)
      end

      by_id
    end

    def self.normalize_keys(keys)
      Array.wrap(keys).map(&:to_s).uniq.first(MAX_KEYS)
    end

    def self.merge_key!(by_id, ids, field_map, clients, key)
      values = field_map.client_query(clients, key)
      ids.each do |client_id|
        by_id[client_id][key] = values[client_id] || values[client_id.to_s]
      end
    rescue ArgumentError
      ids.each { |client_id| by_id[client_id][key] = nil }
    end
  end
end
