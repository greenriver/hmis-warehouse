###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Importers::Loaders
  class CsvFile
    include Enumerable

    attr_reader :filename
    def initialize(filename)
      @filename = filename
    end

    def each
      records_from_csv(filename).each.with_index do |row, idx|
        yield(row)
      rescue StandardError
        line_number = idx + 2 # header and 0-based offset
        raise "Error processing #{filename}:#{line_number}"
      end
    end

    protected

    def records_from_csv(filename)
      io = File.open(filename, 'r')

      # Checking for BOM
      if io.read(3).bytes == [239, 187, 191]
        Rails.logger.info 'Byte-order marker (BOM) found. Skipping it.'
      else
        io.rewind
      end

      CSV.parse(io.read, **csv_config)
    end

    def csv_config
      {
        headers: true,
        skip_lines: /\A\s*\z/,
      }
    end
  end
end
