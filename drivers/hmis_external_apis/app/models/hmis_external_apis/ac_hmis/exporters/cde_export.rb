#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module HmisExternalApis::AcHmis::Exporters
  class CdeExport
    attr_accessor :output

    def initialize(output = StringIO.new)
      require 'csv'
      self.output = output
    end

    def run!
      Rails.logger.info 'Generating CDE report'
      write_row(columns)
      total = cdes.count
      Rails.logger.info "There are #{total} CDEs to export"

      cdes.each.with_index do |cde, i|
        Rails.logger.info "Processed #{i} of #{total}" if (i % 100).zero?
        values = [
          cde.id,
          cde.data_element_definition.key,
          cde.data_element_definition.owner_type.demodulize,
          cde.owner.id,
          cde.value,
          cde.date_created,
          cde.date_updated,
        ]
        write_row(values)
      end
    end

    private

    def columns
      [
        'ResponseID',
        'CustomFieldKey',
        'RecordType',
        'RecordId',
        'Response',
        'DateCreated',
        'DateUpdated',
      ]
    end

    def write_row(row)
      output << CSV.generate_line(row)
    end

    def cdes
      @cdes ||= Hmis::Hud::CustomDataElement.
        where(data_source: data_source).
        preload(:data_element_definition)
    end

    def data_source
      @data_source ||= HmisExternalApis::AcHmis.data_source
    end
  end
end
