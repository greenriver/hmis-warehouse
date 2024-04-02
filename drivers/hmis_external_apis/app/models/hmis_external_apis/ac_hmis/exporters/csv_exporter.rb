#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module HmisExternalApis::AcHmis::Exporters::CsvExporter
  extend ActiveSupport::Concern

  included do
    attr_accessor :output

    def initialize(output = StringIO.new)
      require 'csv'
      self.output = output
    end

    private

    def write_row(row)
      output << CSV.generate_line(row, **csv_config)
    end

    def data_source
      @data_source ||= HmisExternalApis::AcHmis.data_source
    end

    def csv_config
      {
        write_converters: ->(value, _) {
          if value.instance_of?(Date)
            value.strftime('%Y-%m-%d')
          elsif value.respond_to?(:strftime)
            value.strftime('%Y-%m-%d %H:%M:%S')
          else
            value
          end
        },
      }
    end
  end
end
