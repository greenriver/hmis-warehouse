###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'roo'

module HmisExternalApis::TcHmis::Importers::Loaders
  class XlsxFile
    include Enumerable

    attr_accessor :filename, :sheet_number, :header_row_number
    def initialize(filename:, sheet_number:, header_row_number:)
      self.filename = filename
      self.sheet_number = sheet_number
      self.header_row_number = header_row_number
    end

    def each
      records.each_with_index do |row|
        begin
          yield(FileRow.new(row))
        rescue StandardError => e
          # wrap row-level exceptions with file / line number
          msg = "[#{filename}:#{sheet_number}:#{row[:row_number]}] #{e.class.name} #{e.message}"
          wrapped = RuntimeError.new(msg)
          wrapped.set_backtrace(e.backtrace)
          raise wrapped
        end
      end
    end

    protected

    def records
      @records ||= read_records
    end

    def read_records
      xls = Roo::Spreadsheet.open(filename)
      sheet = xls.sheets[sheet_number]

      xls.default_sheet = sheet

      col = 'a'
      fields_by_col_number = {}
      50.times do
        value = xls.cell(header_row_number, col ) rescue nil
        ident = normalize_from_xls(value)
        if ident
          fields_by_col_number[col] = ident
        end
        col = col.next
      end

      ret = []
      last_row = xls.last_row.to_i
      return ret if last_row < 2

      row_number = header_row_number
      (header_row_number + 1).upto(last_row) do |row|
        row_number += 1
        values = { }
        fields_by_col_number.each do |in_col, field|
          value = normalize_from_xls(xls.cell(row, in_col))
          values[field] = value
        end
        next unless values.values.any?

        values[:row_number] = row_number
        values[:filename] = filename
        ret.push(values)
      end
      return ret
    end

    def normalize_from_xls(value)
      value.to_s.strip.presence
    end
  end
end
