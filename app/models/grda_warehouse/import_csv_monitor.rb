###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Per-CSV import monitoring: alerts when row counts for a specific CSV file change
# beyond configured thresholds (by raw count or percent).
# @see docs/features/import-csv-monitoring.md
module GrdaWarehouse
  class ImportCsvMonitor < GrdaWarehouseBase
    attr_accessor :notification_user_ids

    belongs_to :data_source
    has_many :notification_configurations,
             as: :source,
             dependent: :destroy,
             class_name: 'GrdaWarehouse::NotificationConfiguration'

    validates :csv_file_name, presence: true, inclusion: { in: ->(_) { allowed_csv_files } }
    validates :count_increase_threshold, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :count_decrease_threshold, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :percent_increase_threshold,
              numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
              allow_nil: true
    validates :percent_decrease_threshold,
              numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
              allow_nil: true
    validate :at_least_one_threshold

    NOTIFICATION_SLUG = 'csv_change_threshold_exceeded'

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
    # @return [Boolean] true if threshold exceeded and notification should be sent
    def threshold_exceeded?(current:, previous:)
      return false if previous.blank?

      change_count = (current[:pre_processed].to_i - previous[:pre_processed].to_i)
      return false unless direction_matches?(change_count)

      count_exceeded = count_threshold_exceeded?(change_count)
      percent_exceeded = percent_threshold_exceeded?(current: current, previous: previous, change_count: change_count)

      count_exceeded || percent_exceeded
    end

    def notification_configurations_for_slug
      notification_configurations.where(
        notification_slug: NOTIFICATION_SLUG,
      ).where(active: true)
    end

    def items_for(slug)
      return [] unless slug == NOTIFICATION_SLUG

      notification_configurations.where(notification_slug: slug)
    end

    # Human-readable label for which directions this monitor checks (derived from which thresholds are set)
    def alert_direction_label
      has_increase = count_increase_threshold.present? || percent_increase_threshold.present?
      has_decrease = count_decrease_threshold.present? || percent_decrease_threshold.present?
      case [has_increase, has_decrease]
      when [true, false] then 'Only when row count increases'
      when [false, true] then 'Only when row count decreases'
      when [true, true] then 'When row count increases or decreases'
      else '—'
      end
    end

    private def at_least_one_threshold
      return if count_increase_threshold.present? || count_decrease_threshold.present? ||
                percent_increase_threshold.present? || percent_decrease_threshold.present?

      errors.add(:base, 'At least one threshold (count or percent) must be set')
    end

    private def direction_matches?(change_count)
      if change_count.positive?
        count_increase_threshold.present? || percent_increase_threshold.present?
      elsif change_count.negative?
        count_decrease_threshold.present? || percent_decrease_threshold.present?
      else
        false
      end
    end

    private def count_threshold_exceeded?(change_count)
      if change_count.positive?
        count_increase_threshold.present? && change_count >= count_increase_threshold
      elsif change_count.negative?
        count_decrease_threshold.present? && change_count.abs >= count_decrease_threshold
      else
        false
      end
    end

    private def percent_threshold_exceeded?(current:, previous:, change_count:) # rubocop:disable Lint/UnusedMethodArgument
      prev = previous[:pre_processed].to_i
      return false if prev.zero?

      percent_change = (change_count.abs.to_f / prev) * 100

      if change_count.positive?
        percent_increase_threshold.present? && percent_change >= percent_increase_threshold
      elsif change_count.negative?
        percent_decrease_threshold.present? && percent_change >= percent_decrease_threshold
      else
        false
      end
    end
  end
end
