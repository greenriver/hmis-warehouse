###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class CsvDestination
    attr_reader :output_file

    def initialize(output_file)
      @output_file = output_file
    end

    def write(row)
      @csv ||= CSV.open(output_file, 'w')
      unless @headers_written
        @headers_written = true
        @csv << row.keys
      end
      @csv << row.values
    end

    def close
      @csv.close
    end
  end
end
