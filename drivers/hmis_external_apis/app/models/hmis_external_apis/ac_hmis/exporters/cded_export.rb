#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module HmisExternalApis::AcHmis::Exporters
  class CdedExport
    include ::HmisExternalApis::AcHmis::Exporters::CsvExporter

    def run!
      Rails.logger.info 'Generating CDED report'
      write_row(columns)
      total = cdeds.count
      Rails.logger.info "There are #{total} CDEDs to export"

      cdeds.each.with_index do |cded, i|
        Rails.logger.info "Processed #{i} of #{total}" if (i % 100).zero?
        values = [
          cded.key,
          cded.owner_type.demodulize,
          cded.field_type,
        ]
        write_row(values)
      end
    end

    private

    def columns
      [
        'CustomFieldKey',
        'RecordType',
        'FieldType',
      ]
    end

    def cdeds
      @cdeds ||= Hmis::Hud::CustomDataElementDefinition.where(data_source: data_source)
    end
  end
end
