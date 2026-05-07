###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Positive: "Added at least X rows from CSV" - alert when added < X (expect minimum additions).
# Negative: "Removed no more than X rows from CSV" - alert when removed > X (expect limited removals).
# @see docs/features/import-csv-monitoring.md
module GrdaWarehouse::Monitoring::MetricCalculators
  class ImportFileAdditionRemovalDetectionCalculator
    # @param monitor [GrdaWarehouse::ImportCsvMonitor]
    # @param current [Hash] { pre_processed:, added:, removed: } from current import
    # @return [false, Hash] false if not exceeded, or hash with reason:, added:, removed:, threshold:, etc.
    def self.exceeded?(monitor:, current:)
      if monitor.min_additions_threshold.present?
        result = exceeded_min_additions(monitor, current)
        return result if result
      end

      if monitor.max_removals_threshold.present?
        result = exceeded_max_removals(monitor, current)
        return result if result
      end

      false
    end

    def self.exceeded_min_additions(monitor, current)
      added = current[:added].to_i
      threshold = monitor.min_additions_threshold
      return false if added >= threshold

      {
        reason: :min_additions,
        added: added,
        threshold: threshold,
      }
    end

    def self.exceeded_max_removals(monitor, current)
      removed = current[:removed].to_i
      threshold = monitor.max_removals_threshold
      return false if removed <= threshold

      {
        reason: :max_removals,
        removed: removed,
        threshold: threshold,
      }
    end
  end
end
