###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Per-CSV import monitoring: alerts when row counts for a specific CSV file change
# beyond configured numeric thresholds.
# @see docs/features/import-csv-monitoring.md
module GrdaWarehouse
  class ImportCsvMonitor < GrdaWarehouseBase
    acts_as_paranoid

    belongs_to :data_source

    validates :csv_file_name, presence: true, inclusion: { in: ->(_) { allowed_csv_files } }
    validates :csv_file_name, uniqueness: { scope: :data_source_id }
    validates :count_increase_threshold, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :count_decrease_threshold, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :min_additions_threshold, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :max_removals_threshold, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validate :at_least_one_threshold

    NOTIFICATION_SLUG = 'csv_import_threshold_exceeded'

    def self.allowed_csv_files
      version = HudHelper.current_version
      module_name = Rails.application.config.hmis_data_lakes[version]

      if module_name.present?
        module_name.constantize.importable_files_map.keys.freeze
      else
        GrdaWarehouse::Hud.models_by_hud_filename.keys.freeze
      end
    end

    # @param current [Hash] { pre_processed:, added:, removed: } from current import
    # @param previous [Hash, nil] same shape from previous import
    # @return [false, Hash] false if not exceeded, or hash with reason:, change_count:, etc.
    def threshold_exceeded?(current:, previous:)
      # Delta (net change) detection - requires previous
      if count_increase_threshold.present? || count_decrease_threshold.present?
        result = GrdaWarehouse::Monitoring::MetricCalculators::ImportFileDeltaCalculator.exceeded?(
          monitor: self,
          current: current,
          previous: previous,
        )
        return result if result
      end

      # Addition/removal detection - does not require previous
      if min_additions_threshold.present? || max_removals_threshold.present?
        result = GrdaWarehouse::Monitoring::MetricCalculators::ImportFileAdditionRemovalDetectionCalculator.exceeded?(
          monitor: self,
          current: current,
        )
        return result if result
      end

      false
    end

    def csv_import_notifications
      @csv_import_notifications ||= GrdaWarehouse::NotificationConfiguration.where(
        notification_slug: NOTIFICATION_SLUG,
        source: self,
      ).preload(:user).to_a
    end

    def csv_import_notification_user_ids
      csv_import_notifications.select(&:active).map(&:user_id).compact.uniq
    end

    # Active notification configs (for count display)
    def active_notification_count
      csv_import_notifications.count(&:active)
    end

    # User names for active notifications (for tooltip)
    def active_notification_recipient_names
      csv_import_notifications.select(&:active).filter_map { |c| c.user&.name_with_email }.uniq
    end

    def items_for(slug)
      slug == NOTIFICATION_SLUG ? csv_import_notifications : []
    end

    # Human-readable label for which directions this monitor checks (derived from which thresholds are set)
    def alert_direction_label
      parts = []
      parts << 'Row count increase' if count_increase_threshold.present?
      parts << 'Row count decrease' if count_decrease_threshold.present?
      parts << 'Minimum additions' if min_additions_threshold.present?
      parts << 'Maximum removals' if max_removals_threshold.present?
      parts.any? ? parts.join(', ') : '—'
    end

    THRESHOLD_ATTRS = [
      :count_increase_threshold,
      :count_decrease_threshold,
      :min_additions_threshold,
      :max_removals_threshold,
    ].freeze

    private def at_least_one_threshold
      return if THRESHOLD_ATTRS.any? { |attr| send(attr).present? }

      message = 'At least one numeric threshold must be set'
      THRESHOLD_ATTRS.each { |attr| errors.add(attr, message) }
    end
  end
end
