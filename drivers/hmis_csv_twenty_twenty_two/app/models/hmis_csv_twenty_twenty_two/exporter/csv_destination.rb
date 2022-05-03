###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class CsvDestination
    attr_reader :output_file

    def initialize(options)
      @output_file = options[:output_file]
      @keys = options[:hmis_class].hmis_configuration(version: '2022').keys
      @csv ||= CSV.open(@output_file, 'w')
      return if @headers_written

      @headers_written = true
      @csv << @keys
    end

    def write(row)
      @csv ||= CSV.open(@output_file, 'w')
      @csv << row.values_at(*@keys)
    end

    def close
      @csv&.close
    end
  end
end
