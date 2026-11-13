###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Monitoring
  class ThresholdNotificationLog < GrdaWarehouseBase
    self.table_name = 'grda_warehouse_monitoring_threshold_notification_logs'

    EMAIL_TYPES = ['metric_threshold_crossed', 'import_processing'].freeze
    METRIC_THRESHOLD_SUBJECT = 'Metric Threshold Monitoring Alert'
    IMPORT_PROCESSING_SUBJECT = 'HMIS Import Status Update'

    belongs_to :user, optional: true
    belongs_to :message, optional: true

    validates :user_id, presence: true
    validates :email_type, presence: true, inclusion: { in: EMAIL_TYPES }
    validates :sent_at, presence: true

    scope :for_user, ->(user_id) { where(user_id: user_id) }
    scope :recent_first, -> { order(sent_at: :desc) }
    scope :successfully_delivered, -> { where(delivery_failed: false) }
    scope :metric_threshold, -> { where(email_type: 'metric_threshold_crossed') }
    scope :sent_on, ->(date) { where(sent_at: date.all_day) }

    # Integer metric_ids the user was already successfully notified about on `date`.
    # Used by NotifyMetricThresholdCrossingsJob to avoid re-sending the same crossing.
    def self.notified_metric_ids_for(user_id:, date:)
      for_user(user_id).
        metric_threshold.
        successfully_delivered.
        sent_on(date).
        flat_map(&:crossings).
        filter_map { |crossing| crossing['metric_id'] }.
        to_set
    end

    def metric_threshold_crossed?
      email_type == 'metric_threshold_crossed'
    end

    def import_processing?
      email_type == 'import_processing'
    end

    def crossings
      details['crossings'] || []
    end
  end
end
