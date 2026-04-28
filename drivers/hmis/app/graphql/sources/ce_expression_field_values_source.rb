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

    def self.normalize_keys!(keys)
      arr = Array.wrap(keys).map(&:to_s).uniq.sort
      raise ArgumentError, "CeExpressionFieldValuesSource accepts at most #{MAX_KEYS} expression keys (#{arr.size} given)" if arr.size > MAX_KEYS

      arr
    end

    def initialize(keys:)
      @keys = self.class.normalize_keys!(keys)
    end

    # @return [Array<Hash{String => Object}>] One hash per element of `destination_client_ids`, same order
    def fetch(destination_client_ids)
      batch = Array.wrap(destination_client_ids)
      return batch.map { {} } if @keys.empty?

      ordered_ids = batch.map(&:to_i)
      unique_ids = ordered_ids.uniq
      clients = GrdaWarehouse::Hud::Client.where(id: unique_ids)
      field_map = Hmis::Ce::Match::Expression::FieldMap.new

      # { destination_client_id => { key => value } }
      id_to_values = unique_ids.index_with { {} }

      @keys.each do |key|
        values = field_map.client_query(clients, key)
        unique_ids.each { |id| id_to_values[id][key] = values[id] }
      end

      # return in the same order as the input
      ordered_ids.map { |id| id_to_values[id] || {} }
    end

    # By default, GraphQL::Dataloader buckets sources by constructor arguments. Override
    # `batch_key_for` so the same logical field set batches together regardless of key
    # order or String/Symbol element types (same normalization as `#initialize`).
    def self.batch_key_for(*_batch_args, keys:)
      [normalize_keys!(keys)]
    end
  end
end
