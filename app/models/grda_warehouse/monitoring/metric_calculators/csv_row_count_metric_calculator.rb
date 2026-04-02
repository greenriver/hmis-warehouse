###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Metric calculator for CSV row counts per DataSource.
# Uses latest completed ImporterLog summary - not a scheduled calculator.
# @see docs/features/import-csv-monitoring.md
module GrdaWarehouse::Monitoring::MetricCalculators
  class CsvRowCountMetricCalculator < BaseCalculator
    # Batch calculation for DataSource entities.
    # Requires metric with subtype (e.g., Client.csv). Pass via metric: for multi-metric class.
    # Returns hash of { data_source_id => pre_processed count }
    # Uses calculation_date to scope to imports completed on or before that date.
    def self.calculate_batch(entities, calculation_date, metric: nil)
      return {} if metric.blank? || metric.subtype.blank?

      csv_file_name = metric.subtype
      result = {}

      entities.each do |data_source|
        log = HmisCsvImporter::Importer::ImporterLog.
          where(data_source_id: data_source.id).
          where(status: 'complete').
          where(completed_at: ..calculation_date.end_of_day).
          order(completed_at: :desc).
          first

        next if log.blank? || log.summary.blank?

        data = log.summary[csv_file_name]
        next if data.blank?

        result[data_source.id] = data['pre_processed'].to_i
      end

      result
    end

    def self.metric_definition_attributes
      {
        name: 'csv_row_count_placeholder',
        display_name: 'CSV Row Count (placeholder)',
        description: 'Per-CSV row count from import summary',
        entity_type: 'GrdaWarehouse::DataSource',
        calculator_class: name,
        category: 'csv_import',
        subtype: nil,
        active: false,
        alert_code: 'csv_import_threshold_exceeded',
      }
    end
  end
end
