###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'roo'

module HmisExternalApis::TcHmis::Importers::Loaders
  class XlsxFile
    include SafeInspectable
    include Enumerable

    attr_accessor :filename, :sheet_number, :header_row_number
    def initialize(filename:, sheet_number:, header_row_number:)
      self.filename = filename
      self.sheet_number = sheet_number
      self.header_row_number = header_row_number
    end

    def each
      records.each do |row|
        yield(FileRow.new(row))
      rescue StandardError => e
        # wrap row-level exceptions with file / line number
        msg = "[#{filename}:#{sheet_number}:#{row[:row_number]}] #{e.class.name} #{e.message}"
        wrapped = RuntimeError.new(msg)
        wrapped.set_backtrace(e.backtrace)
        raise wrapped
      end
    end

    protected

    def records
      @records ||= read_records
    end

    # build a list of header names and columns. Multiple columns with the same name ard grouped together
    # {'Enrollment ID' => ['a'], 'Nickname' => ['d', 'e','f']}
    def build_cols_by_field(xls)
      col = 'a'
      result = {}
      500.times do
        value = begin
                  xls.cell(header_row_number, col)
                rescue StandardError
                  nil
                end
        field = normalize_col(value)
        result[field ] ||= []
        result[field] << col
        col = col.next
      end
      result
    end

    def read_records
      xls = Roo::Spreadsheet.open(filename)
      sheet = xls.sheets[sheet_number]

      xls.default_sheet = sheet
      cols_by_field = build_cols_by_field(xls)

      ret = []
      last_row = xls.last_row.to_i
      return ret if last_row <= header_row_number

      cur_row_number = header_row_number
      (header_row_number + 1).upto(last_row) do |row|
        cur_row_number += 1
        values = {}
        cols_by_field.each do |field, sheet_cols|
          values[field] = sheet_cols.map do |sheet_col|
            normalize_value(xls.cell(row, sheet_col))
          end
        end
        next unless values.values.any?

        values[:row_number] = cur_row_number
        values[:filename] = filename
        ret.push(values)
      end
      return ret
    end

    def normalize_value(value)
      value&.strip.presence
    end

    def normalize_col(value)
      value&.gsub(/\s+/, ' ').presence
    end
  end
end
