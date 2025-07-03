###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Exporter
  class Export
    def self.export_scope(export:, hmis_class:, **_)
      implementation_id = "#{ENV['CLIENT']} Open Path Warehouse"
      implementation_id += " #{Rails.env.titleize}" unless Rails.env.production?
      source_id = export.filter.coc_codes.join(';') if export.filter.coc_codes.present?
      source_id ||= Translation.translate('Open Path HMIS Warehouse')
      [
        hmis_class.new(
          ExportID: export.export_id,
          SourceType: export.source_type,
          # If SourceType = 1, this field may not be null and must identify the HUD CoC Code/s of the HMIS implementation from which data are being exported in the format of two letters, a dash, and 3 numbers.
          # ^[a-zA-Z]{2}-[0-9]{3}$
          # If more than one CoC Code was selected by the user for export, all selected CoC Codes should be included here in a semicolon-separated list
          # (ex. “XX-501;XX-502”)
          # If SourceType <> 1, this field may be null or used to specify other characteristics, as agreed upon by sender and receiver.
          SourceID: source_id[0..31], # potentially more than one CoC
          SourceName: Translation.translate('Open Path HMIS Warehouse'),
          SourceContactFirst: export&.user&.first_name || 'Automated',
          SourceContactLast: export&.user&.last_name || 'Export',
          SourceContactPhone: nil,
          SourceContactExtension: nil,
          SourceContactEmail: export&.user&.email,
          ExportDate: Date.current,
          ExportStartDate: export.start_date,
          ExportEndDate: export.end_date,
          SoftwareName: Translation.translate('OpenPath HMIS Warehouse'),
          SoftwareVersion: 1,
          CSVVersion: '2026 v1.3',
          ExportPeriodType: export.period_type,
          ExportDirective: export.directive || 2,
          HashStatus: export.hash_status,
          ImplementationID: implementation_id,
        ),
      ]
    end

    def self.transforms
      [
        HmisCsvTwentyTwentySix::Exporter::FakeData,
      ]
    end

    def self.csv_header_override(keys)
      keys
    end
  end
end
