###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memery'

# This defines two thresholds for imports that will potentially trigger notifications
# 1. When an import is going to add or remove a significant percentage of the existing records, and that change is greater than the min count threshold
# 2. When an import contains a high percentage of errors, and that change is greater than the min count threshold
module GrdaWarehouse
  class ImportThreshold < GrdaWarehouseBase
    include Memery
    belongs_to :data_source

    validates :error_count_min_threshold, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :error_percent_threshold, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
    validates :record_count_change_min_threshold, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :record_count_change_percent_threshold, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

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

    # Gather users from notification configurations into 3 categories
    # 1. Those that have notifications for errors
    # 2. Those that have notifications for count changes
    # 3. Those that have both
    def send_status_notifications(import_log_id:, error_threshold_met:, record_count_threshold_met:, paused:)
      return unless error_threshold_met || record_count_threshold_met

      receive_both_user_ids = error_count_notification_user_ids & record_change_count_notification_user_ids

      # Handle users who subscribe to both types - they get one notification containing both status types
      if error_threshold_met || record_count_threshold_met
        User.where(id: receive_both_user_ids).find_each do |user|
          NotifyUser.with(
            user: user,
            import_log_id: import_log_id,
            data_source: data_source,
            error: error_threshold_met,
            count: record_count_threshold_met,
            paused: paused,
          ).import_processing.deliver_later
        end
      end

      only_error_user_ids = error_count_notification_user_ids - receive_both_user_ids
      # Notify where the user receives only the error notification
      if error_threshold_met
        User.where(id: only_error_user_ids).find_each do |user|
          NotifyUser.with(
            user: user,
            import_log_id: import_log_id,
            data_source: data_source,
            error: error_threshold_met,
            count: false, # never notify on counts in this scenario
            paused: paused,
          ).import_processing.deliver_later
        end
      end

      only_count_user_ids = record_change_count_notification_user_ids - receive_both_user_ids
      # Notify where the user receives only the record count notification
      if record_count_threshold_met # rubocop:disable Style/GuardClause
        User.where(id: only_count_user_ids).find_each do |user|
          NotifyUser.with(
            user: user,
            import_log_id: import_log_id,
            data_source: data_source,
            error: false, # never notify on errors in this scenario
            count: record_count_threshold_met,
            paused: paused,
          ).import_processing.deliver_later
        end
      end
    end

    memoize def error_count_notification_user_ids
      error_count_notifications.select(&:active).map(&:user_id)
    end

    memoize def record_change_count_notification_user_ids
      record_count_change_notifications.select(&:active).map(&:user_id)
    end

    def error_count_notifications
      @error_count_notifications ||= GrdaWarehouse::NotificationConfiguration.where(
        notification_slug: error_count_notification_event,
        source: self,
      ).preload(:user).
        to_a
    end

    def record_count_change_notifications
      @record_count_change_notifications ||= GrdaWarehouse::NotificationConfiguration.where(
        notification_slug: record_count_change_notification_event,
        source: self,
      ).preload(:user).
        to_a
    end

    def valid_notification_slug(slug)
      valid_slug = [
        record_count_change_notification_event,
        error_count_notification_event,
      ].detect { |m| m == slug }
      return valid_slug if valid_slug.present?

      raise "Unknown slug #{slug}"
    end

    def items_for(slug)
      case slug
      when record_count_change_notification_event
        record_count_change_notifications
      when error_count_notification_event
        error_count_notifications
      end
    end

    def record_count_change_notification_event
      'count_threshold_exceeded'
    end

    def error_count_notification_event
      'error_threshold_exceeded'
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
