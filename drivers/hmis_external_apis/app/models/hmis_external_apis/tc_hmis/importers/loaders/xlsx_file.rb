###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'roo'

# reads xls from ETO touch points. These files have two headers rows. One row has the optional element id and one row wit hthe label. The element ids are unique, the labels are not.

module HmisExternalApis::TcHmis::Importers::Loaders
  class XlsxFile
    include SafeInspectable
    include Enumerable

    attr_accessor :filename, :sheet_number, :header_row_number, :field_id_row_number

    # @param [String] filename this full path to the file
    # @param [Integer] sheet_number
    # @param [Integer] header_row_number each column has a label
    # @param [Integer] field_id_row_number each column may have an id
    def initialize(filename:, sheet_number:, header_row_number:, field_id_row_number: nil)
      self.filename = filename
      self.sheet_number = sheet_number
      self.header_row_number = header_row_number
      self.field_id_row_number = field_id_row_number
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

    # build a list of header names, column labels, and column ids (ETO element id)
    def sheet_headers(xls)
      ret = []
      500.times do |col_idx|
        col = column_to_letter(col_idx)
        label = begin
                  xls.cell(header_row_number, col)
                rescue StandardError
                  nil
                end
        label = normalize_col(label)
        next unless label # skip empty labels

        if field_id_row_number
          id = begin
                  xls.cell(field_id_row_number, col)
                rescue StandardError
                  nil
                end
          id = normalize_col(id)&.to_i
          # column id can be missing
        else
          id = nil
        end

        ret << [label, id, col]
      end
      ret
    end

    def column_to_letter(column_number)
      letter = ''
      while column_number >= 0
        remainder = column_number % 26
        letter = (65 + remainder).chr + letter
        column_number = column_number / 26 - 1
      end
      letter
    end

    # [
    #   {label => { (element id || col) => 'value'} }
    # ]
    def read_records
      xls = Roo::Spreadsheet.open(filename)
      sheet = xls.sheets[sheet_number]

      xls.default_sheet = sheet
      headers = sheet_headers(xls)

      ret = []
      last_row = xls.last_row.to_i
      return ret if last_row <= header_row_number

      cur_row_number = header_row_number
      (header_row_number + 1).upto(last_row) do |row|
        cur_row_number += 1
        values = {}
        headers.each do |label, id, col|
          values[label] ||= {}
          values[label][id || col] = normalize_value(xls.cell(row, col))
        end
        next unless values.values.any?

        values[:row_number] = cur_row_number
        values[:filename] = filename
        ret.push(values)
      end
      return ret
    end

    def normalize_value(value)
      case value
      when String
        value&.strip.presence
      else
        value
      end
    end

    def normalize_col(value)
      case value
      when String
        value&.gsub(/\s+/, ' ').presence
      else
        value
      end
    end
  end
end
