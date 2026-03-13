###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Calculator-like component for extracting row counts from import summaries.
# Not a BaseCalculator subclass - uses import logs instead of warehouse tables.
# @see docs/features/import-csv-monitoring.md
module GrdaWarehouse::Monitoring
  class CsvRowCountCalculator
    # @param importer_log [HmisCsvImporter::Importer::ImporterLog]
    # @param csv_file_name [String] e.g. 'Client.csv'
    # @return [Hash] { pre_processed:, added:, removed: } or empty hash if file not in summary
    def self.current_value(importer_log:, csv_file_name:)
      return {} if importer_log.blank? || importer_log.summary.blank?

      data = importer_log.summary[csv_file_name]
      return {} if data.blank?

      {
        pre_processed: data['pre_processed'].to_i,
        added: data['added'].to_i,
        removed: data['removed'].to_i,
      }
    end

    # @param data_source [GrdaWarehouse::DataSource]
    # @param csv_file_name [String]
    # @param exclude_importer_log_id [Integer] ID of current import to exclude from "previous"
    # @return [Hash, nil] { pre_processed:, added:, removed: } from prior completed import, or nil if none
    def self.previous_value(data_source:, csv_file_name:, exclude_importer_log_id:)
      previous_log = HmisCsvImporter::Importer::ImporterLog.
        where(data_source_id: data_source.id).
        where(status: 'complete').
        where(id: ...exclude_importer_log_id).
        order(completed_at: :desc).
        first

      return nil if previous_log.blank?

      current_value(importer_log: previous_log, csv_file_name: csv_file_name)
    end
  end
end
