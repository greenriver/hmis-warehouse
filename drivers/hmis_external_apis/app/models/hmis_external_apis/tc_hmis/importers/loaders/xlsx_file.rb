# frozen_string_literal: true

###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'creek'

# reads xls from ETO touch points. These files have two headers rows. One row has the optional element id and one row wit hthe label. The element ids are unique, the labels are not.
#
# @param [String] filename this full path to the file
# @param [Integer] sheet_number
# @param [Integer] header_row_number each column has a label
# @param [Integer] field_id_row_number each column may have an id
module HmisExternalApis::TcHmis::Importers::Loaders
  class XlsxFile
    include SafeInspectable
    include Enumerable

    attr_accessor :filename, :sheet_number, :header_row_number, :field_id_row_number

    def initialize(filename:, sheet_number:, header_row_number:, field_id_row_number: nil)
      self.filename = filename
      self.sheet_number = sheet_number
      self.header_row_number = header_row_number
      self.field_id_row_number = field_id_row_number
    end

    def each
      creek = Creek::Book.new(filename)
      sheet = creek.sheets[sheet_number]
      headers = sheet_headers(sheet)

      sheet.simple_rows.each_with_index do |row, index|
        next if index + 1 <= header_row_number

        row_data = process_row(row, headers, index + 1)
        next unless row_data

        yield(FileRow.new(row_data))
      rescue StandardError => e
        msg = "[#{filename}:#{sheet_number}:#{index + 1}] #{e.class.name} #{e.message}"
        wrapped = RuntimeError.new(msg)
        wrapped.set_backtrace(e.backtrace)
        raise wrapped
      end
      GC.start
      nil
    end

    private

    def get_row(sheet, number)
      sheet.simple_rows.each_with_index do |row, idx|
        return row if idx == number - 1
      end
    end

    def sheet_headers(sheet)
      headers_row = get_row(sheet, header_row_number)
      field_ids_row = get_row(sheet, field_id_row_number) if field_id_row_number
      headers = []

      [headers_row, field_ids_row].compact.flat_map(&:keys).uniq do |col|
        label = normalize_col(headers_row[col])
        id = field_ids_row ? normalize_col(field_ids_row[col])&.to_i : nil

        headers << [label, id, col] if label || id
      end
      headers
    end

    def process_row(row, headers, row_number)
      by_id = {}
      row_data = { filename: filename, by_id: by_id, row_number: row_number }
      blank = true
      headers.each do |label, id, col|
        value = normalize_value(row[col])
        next unless value

        blank = false

        row_data[label] = value if value
        by_id[id] = value if id
      end
      blank ? nil : row_data
    end

    def normalize_value(value)
      case value
      when String
        value.strip.presence
      else
        value
      end
    end

    def normalize_col(value)
      case value
      when String
        value&.gsub(/\s+/, ' ')&.strip.presence
      else
        value
      end
    end
  end
end
