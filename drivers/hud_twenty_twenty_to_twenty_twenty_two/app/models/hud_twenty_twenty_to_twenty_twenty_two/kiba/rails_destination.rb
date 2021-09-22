###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Kiba
  class RailsDestination
    BATCH_SIZE = 1_000

    def initialize(klass)
      @destination_class = klass
      @batch = []
    end

    def write(row)
      @batch << row
      update_batch if @batch.size >= BATCH_SIZE
    end

    def close
      update_batch if @batch.size.positive?
    end

    private def update_batch
      valid_keys = @destination_class.hmis_configuration(version: '2022').keys.map(&:to_s) + ['id']
      @batch.map! do |row|
        row.select { |key, _| key.in?(valid_keys) }
      end
      @destination_class.import(
        @batch,
        on_duplicate_key_update: {
          conflict_target: [:id],
          columns: @batch.first.keys,
        },
      )
      @batch = []
    end
  end
end
