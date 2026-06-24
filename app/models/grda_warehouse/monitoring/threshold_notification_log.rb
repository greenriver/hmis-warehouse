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
    THRESHOLD_SUBJECTS = [METRIC_THRESHOLD_SUBJECT, IMPORT_PROCESSING_SUBJECT].freeze

    belongs_to :user, optional: true
    belongs_to :message, optional: true

    validates :user_id, presence: true
    validates :email_type, presence: true, inclusion: { in: EMAIL_TYPES }
    validates :sent_at, presence: true

    scope :for_user, ->(user_id) { where(user_id: user_id) }
    scope :recent_first, -> { order(sent_at: :desc) }

    # Backfills ThresholdNotificationLog stubs from historical Message records for all users.
    # Run from the console: GrdaWarehouse::Monitoring::ThresholdNotificationLog.backfill
    # TODO: Remove after 2026-09-15 once historical messages are migrated.
    def self.backfill
      TodoOrDie('Remove threshold notification history backfill', by: Date.new(2026, 9, 15))
      existing_message_ids = where.not(message_id: nil).pluck(:message_id).to_set

      subject_filter = THRESHOLD_SUBJECTS.
        map { |subj| Message.arel_table[:subject].matches("%#{subj}%") }.
        reduce(:or)

      Message.
        where(subject_filter).
        where.not(id: existing_message_ids).
        find_each do |message|
          create!(
            user_id: message.user_id,
            message_id: message.id,
            email_type: subject_to_email_type(message.subject),
            sent_at: message.created_at,
            details: Monitoring::HistoricalNotificationParser.parse(message),
          )
        end
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

    private_class_method def self.subject_to_email_type(subject)
      subject.include?(METRIC_THRESHOLD_SUBJECT) ? 'metric_threshold_crossed' : 'import_processing'
    end
  end
end
