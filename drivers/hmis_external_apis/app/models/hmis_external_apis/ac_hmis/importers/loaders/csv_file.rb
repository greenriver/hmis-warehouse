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

    class CsvFileRowWrapper
      attr_accessor :row, :line_number, :filename
      delegate :[], :to_h, to: :row
      def initialize(row, filename, line_number)
        self.row = row
        self.filename = filename
        self.line_number = line_number
      end

      def context
        "#{filename}:#{line_number}"
      end
    end

    def each
      records_from_csv(filename).each.with_index do |row, line_number|
        yield(CsvFileRowWrapper.new(row, filename, line_number))
      rescue StandardError => e
        # wrap row-level exceptions with file / line number
        wrapped = RuntimeError.new("[#{filename}:#{line_number}] #{e.class.name} #{e.message}")
        wrapped.set_backtrace(e.backtrace)
        raise wrapped
      end
    end

    protected

    def records_from_csv(filename)
      io = File.open(filename, encoding: 'iso-8859-1')

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
        quote_char: "\x00", # can't use `"` as files are not properly quoted. Hopefully non-printing char isn't in data
      }
    end
  end
end
