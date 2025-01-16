###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# This defines two thresholds for imports that will potentially trigger notifications
# 1. When an import is going to add or remove a significant percentage of the existing records, and that change is greater than the min count threshold
# 2. When an import contains a high percentage of errors, and that change is greater than the min count threshold
module GrdaWarehouse
  class ImportThreshold < GrdaWarehouseBase
    belongs_to :data_source

    ##
    # Determines whether the record count change during an import meets or exceeds
    # the defined thresholds for triggering a notification.
    #
    # @param total [Integer] The total number of existing records before the import.
    # @param count [Integer] The number of records being added or removed.
    # @return [Boolean] Returns `true` if the count meets or exceeds both the
    #   minimum count threshold and the percentage change threshold, otherwise `false`.
    #
    # The method performs the following checks:
    # - Returns `false` if any of the required threshold values (`record_count_change_min_threshold`
    #   or `record_count_change_percent_threshold`) or input parameters (`total` or `count`) are missing.
    # - Returns `false` if `count` or `total` is zero (to avoid division errors and meaningless calculations).
    # - Returns `false` if `count` is below the `record_count_change_min_threshold`.
    # - Returns `false` if the percentage change is below the `record_count_change_percent_threshold`.
    # - Returns `true` if all conditions are met.
    #
    def record_count_threshold_reached?(total, count)
      return false unless record_count_change_min_threshold && record_count_change_percent_threshold && total && count
      return false if count.zero? || total.zero?
      return false if count < record_count_change_min_threshold

      percent_change = (count / total.to_f) * 100
      return false if percent_change < record_count_change_percent_threshold

      true
    end

    ##
    # Determines whether the count of errors during an import meets or exceeds
    # the defined thresholds for triggering a notification.
    #
    # @param total [Integer] The total number of records in the import.
    # @param count [Integer] The number of records containing an error.
    # @return [Boolean] Returns `true` if the count meets or exceeds both the
    #   minimum count threshold and the percentage change threshold, otherwise `false`.
    #
    # The method performs the following checks:
    # - Returns `false` if any of the required threshold values (`error_count_min_threshold`
    #   or `error_percent_threshold`) or input parameters (`total` or `count`) are missing.
    # - Returns `false` if `count` or `total` is zero (to avoid division errors and meaningless calculations).
    # - Returns `false` if `count` is below the `error_count_min_threshold`.
    # - Returns `false` if the percentage change is below the `error_percent_threshold`.
    # - Returns `true` if all conditions are met.
    #
    def error_count_threshold_reached?(total, count)
      return false unless error_count_min_threshold && error_percent_threshold && total && count
      return false if count.zero? || total.zero?
      return false if count < error_count_min_threshold

      percent_change = (count / total.to_f) * 100
      return false if percent_change < error_percent_threshold

      true
    end

    def self.known_params
      [
        :record_count_change_min_threshold,
        :record_count_change_percent_threshold,
        :error_count_min_threshold,
        :error_percent_threshold,
        :pause_on_record_count_threshold,
        :pause_on_error_threshold,
      ]
    end
  end
end
