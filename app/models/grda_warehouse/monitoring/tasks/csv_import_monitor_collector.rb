###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Collects per-CSV row count metrics after each import.
# Uses MetricSnapshot for storage, ImportCsvMonitor for config.
# Triggered from importer post_process.
# @see docs/features/import-csv-monitoring.md
module GrdaWarehouse::Monitoring::Tasks
  class CsvImportMonitorCollector
    def self.run!(data_source:, importer_log:, import_log: nil)
      new(
        data_source: data_source,
        importer_log: importer_log,
        import_log: import_log,
      ).run!
    end

    def initialize(data_source:, importer_log:, import_log: nil)
      @data_source = data_source
      @importer_log = importer_log
      @import_log = import_log
    end

    def run!
      GrdaWarehouse::Monitoring::MetricDefinition.maintain_csv_metrics!

      monitors = @data_source.import_csv_monitors.where(active: true)
      return if monitors.empty?

      monitors.each do |monitor|
        process_monitor(monitor)
      end
    end

    private def process_monitor(monitor)
      return if @importer_log.summary.blank?
      return unless @importer_log.summary.key?(monitor.csv_file_name)

      current = GrdaWarehouse::Monitoring::CsvRowCountCalculator.current_value(
        importer_log: @importer_log,
        csv_file_name: monitor.csv_file_name,
      )
      return if current.blank?

      metric_def = metric_definition_for(monitor.csv_file_name)
      return unless metric_def

      previous = previous_value_from_snapshot(metric_def)
      previous ||= GrdaWarehouse::Monitoring::CsvRowCountCalculator.previous_value(
        data_source: @data_source,
        csv_file_name: monitor.csv_file_name,
        exclude_importer_log_id: @importer_log.id,
      )

      current_value = current[:pre_processed].to_i
      snapshot = latest_snapshot(metric_def)

      if snapshot
        update_snapshot(snapshot, current_value)
      else
        create_new_snapshot(metric_def, current_value)
      end

      alert_result = monitor.threshold_exceeded?(current: current, previous: previous)
      notify_monitor_exceeded(monitor, current: current, previous: previous, alert_result: alert_result) if alert_result
    end

    private def metric_definition_for(csv_file_name)
      GrdaWarehouse::Monitoring::MetricDefinition.find_by(
        entity_type: 'GrdaWarehouse::DataSource',
        subtype: csv_file_name,
      )
    end

    private def previous_value_from_snapshot(metric_def)
      snapshot = latest_snapshot(metric_def)
      return nil unless snapshot

      { pre_processed: snapshot.current_value, added: 0, removed: 0 }
    end

    private def latest_snapshot(metric_def)
      GrdaWarehouse::Monitoring::MetricSnapshot.
        where(
          entity_type: @data_source.class.name,
          entity_id: @data_source.id,
          metric_definition_id: metric_def.id,
        ).
        order(initial_observation_date: :desc).
        first
    end

    private def create_new_snapshot(metric_def, value)
      GrdaWarehouse::Monitoring::MetricSnapshot.create!(
        entity: @data_source,
        metric_definition: metric_def,
        initial_observation_date: Date.current,
        current_observation_date: Date.current,
        initial_value: value,
        current_value: value,
        calculation_version: '1.0.0',
      )
    end

    private def update_snapshot(snapshot, value)
      snapshot.update!(
        current_value: value,
        current_observation_date: Date.current,
      )
    end

    private def notify_monitor_exceeded(monitor, current:, previous:, alert_result:)
      user_ids = recipient_user_ids(monitor)
      return if user_ids.empty?

      change_count = alert_result[:change_count]
      change_count ||= 0

      import_log_id = @import_log&.id

      User.where(id: user_ids).find_each do |user|
        NotifyUser.with(
          user: user,
          import_csv_monitor: monitor,
          data_source: @data_source,
          csv_file_name: monitor.csv_file_name,
          current: current,
          previous: previous || {},
          change_count: change_count,
          import_log_id: import_log_id,
          alert_reason: alert_result[:reason],
          alert_detail: alert_result,
        ).csv_change_threshold_exceeded.deliver_later
      end
    end

    private def recipient_user_ids(monitor)
      monitor.csv_import_notification_user_ids
    end
  end
end
