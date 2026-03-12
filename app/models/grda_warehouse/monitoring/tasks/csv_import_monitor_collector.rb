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

      monitors.each { |monitor| process_monitor(monitor) }
    end

    # @return [Boolean] true if a crossing snapshot was created
    private def process_monitor(monitor)
      return false if @importer_log.summary.blank?
      return false unless @importer_log.summary.key?(monitor.csv_file_name)

      current = GrdaWarehouse::Monitoring::CsvRowCountCalculator.current_value(
        importer_log: @importer_log,
        csv_file_name: monitor.csv_file_name,
      )
      return false if current.blank?

      metric_def = metric_definition_for(monitor.csv_file_name)
      return false unless metric_def

      previous = previous_value_from_snapshot(metric_def)
      previous ||= GrdaWarehouse::Monitoring::CsvRowCountCalculator.previous_value(
        data_source: @data_source,
        csv_file_name: monitor.csv_file_name,
        exclude_importer_log_id: @importer_log.id,
      )

      alert_result = monitor.threshold_exceeded?(current: current, previous: previous)
      current_value = current[:pre_processed].to_i
      snapshot = latest_snapshot(metric_def)

      # If the current_observation_date and initial_observation_date are today, this indicates a previous
      # import already crossed a threshold and we don't need to do anything.

      if alert_result
        # If today's snapshot has an initial_observation_date of today, something earlier crossed a threshold, do nothing
        return false if snapshot && snapshot.initial_observation_date == Date.current

        # Today's days snaphot was created previously,
        # need to create a new snapshot to indicate we have crossed a threshold
        create_new_snapshot(metric_def, current_value)

        true
      else
        # If a snapshot already existed that was updated today, don't overwrite it
        return false if snapshot && snapshot.current_observation_date == Date.current

        # If we have a snapshot, but it hasn't been updated today, updated it
        if snapshot
          update_snapshot(snapshot, current_value)
          return false
        end

        # First ever observation
        create_new_snapshot(metric_def, current_value)
      end
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
  end
end
