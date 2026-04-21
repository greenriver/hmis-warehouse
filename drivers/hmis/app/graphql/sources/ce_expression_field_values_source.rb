###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Sources
  class CeExpressionFieldValuesSource < GraphQL::Dataloader::Source
    def initialize(keys:, current_date: Date.current)
      @keys = keys
      @current_date = current_date
    end

    def fetch(destination_client_ids)
      Rails.logger.info(">>> Fetching expression field values for #{destination_client_ids.size} destination clients (#{@keys.join(', ')})")
      by_id = Hmis::Ce::ExpressionFieldValues.for_destination_clients(
        destination_client_ids: destination_client_ids.uniq,
        keys: @keys,
        current_date: @current_date,
      )
      destination_client_ids.map { |id| by_id[id.to_i] || by_id[id] || {} }
    end

    def self.batch_key_for(*_batch_args, keys:, current_date: Date.current)
      [Array.wrap(keys).map(&:to_s).sort, current_date]
    end
  end
end
