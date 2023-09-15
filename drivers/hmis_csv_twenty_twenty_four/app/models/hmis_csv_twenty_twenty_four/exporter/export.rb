###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour::Exporter
  class Export
    def self.export_scope(export:, hmis_class:, **_)
      [
        hmis_class.new(
          ExportID: export.export_id,
          SourceType: 3, # data warehouse
          SourceID: Translation.translate('Boston DND Warehouse')[0..31], # potentially more than one CoC
          SourceName: Translation.translate('Boston DND Warehouse'),
          SourceContactFirst: export&.user&.first_name || 'Automated',
          SourceContactLast: export&.user&.last_name || 'Export',
          SourceContactEmail: export&.user&.email,
          ExportDate: Date.current,
          ExportStartDate: export.start_date,
          ExportEndDate: export.end_date,
          SoftwareName: Translation.translate('OpenPath HMIS Warehouse'),
          SoftwareVersion: 1,
          CSVVersion: '2024 v1.2',
          ExportPeriodType: export.period_type,
          ExportDirective: export.directive || 2,
          HashStatus: export.hash_status,
        ),
      ]
    end

    def self.transforms
      [
        HmisCsvTwentyTwentyFour::Exporter::FakeData,
      ]
    end

    def self.csv_header_override(keys)
      keys
    end
  end
end
