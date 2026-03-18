###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Daily (most-recent import) delta for a given CSV file in an import.
# Compares net change (pre_processed diff) to count_increase/count_decrease thresholds.
# @see docs/features/import-csv-monitoring.md
module GrdaWarehouse::Monitoring::MetricCalculators
  class ImportFileDeltaCalculator
    # @param monitor [GrdaWarehouse::ImportCsvMonitor]
    # @param current [Hash] { pre_processed:, added:, removed: } from current import
    # @param previous [Hash, nil] same shape from previous import
    # @return [false, Hash] false if not exceeded, or hash with reason:, change_count:, etc.
    def self.exceeded?(monitor:, current:, previous:)
      return false if previous.blank?

      change_count = current[:pre_processed].to_i - previous[:pre_processed].to_i
      return false if change_count.zero?

      if change_count.positive?
        return false unless monitor.count_increase_threshold.present?
        return false unless change_count >= monitor.count_increase_threshold

        return {
          reason: :delta_increase,
          change_count: change_count,
          previous_count: previous[:pre_processed].to_i,
          current_count: current[:pre_processed].to_i,
        }
      end

      # change_count.negative?
      return false unless monitor.count_decrease_threshold.present?
      return false unless change_count.abs >= monitor.count_decrease_threshold

      {
        reason: :delta_decrease,
        change_count: change_count,
        previous_count: previous[:pre_processed].to_i,
        current_count: current[:pre_processed].to_i,
      }
    end
  end
end
