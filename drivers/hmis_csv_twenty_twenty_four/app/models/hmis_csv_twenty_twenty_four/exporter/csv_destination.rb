###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour::Exporter
  class CsvDestination
    attr_reader :output_file

    def initialize(options)
      @output_file = options[:output_file]
      @keys = options[:hmis_class].hmis_configuration(version: '2024').keys
      @csv ||= CSV.open(@output_file, 'wb', force_quotes: true)
      return if @headers_written

      @headers_written = true
      @csv << options[:destination_class].csv_header_override(@keys)
    end

    def write(row)
      @csv ||= CSV.open(@output_file, 'wb', force_quotes: true)
      @csv << row.values_at(*@keys)
    end

    def close
      @csv&.close
    end
  end
end
