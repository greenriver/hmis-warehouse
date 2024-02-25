# frozen_string_literal: true

###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'roo'

# Streaming xls reader for ETO touch points. These files have two headers rows. One row has the optional element id and one row with the label. The element ids are unique, the labels are not.
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
      xlsx = Roo::Excelx.new(filename)
      row_number = header_row_number
      sheet = xlsx.sheet(sheet_number)
      headers = sheet_headers(sheet)
      sheet.each_row_streaming(offset: header_row_number, pad_cells: true) do |row|
        row_number += 1
        row_data = process_row(row, headers, row_number)
        next unless row_data

        yield(FileRow.new(row_data))
      rescue StandardError => e
        msg = "[#{filename}:#{sheet_number}:#{row_number}] #{e.class.name} #{e.message}"
        wrapped = RuntimeError.new(msg)
        wrapped.set_backtrace(e.backtrace)
        raise wrapped
      end
      GC.start
      nil
    end

    private

    def get_row(sheet, number)
      # rubocop:disable Lint/UnreachableLoop
      sheet.each_row_streaming(offset: number - 1, max_rows: 0, pad_cells: true) do |row|
        return row
      end
      # rubocop:enable Lint/UnreachableLoop
    end

    def sheet_headers(sheet)
      headers_row = get_row(sheet, header_row_number)
      field_ids_row = get_row(sheet, field_id_row_number) if field_id_row_number
      headers = []

      headers_row.each_with_index do |col, idx|
        label = normalize_col(col&.value)
        id = field_ids_row[idx]&.value if field_ids_row
        headers << [label, id]
      end
      headers
    end

    def process_row(row, headers, row_number)
      by_id = {}
      row_data = { filename: filename, by_id: by_id, row_number: row_number }
      blank = true
      headers.each_with_index do |(label, id), index|
        next unless label || id

        value = normalize_value(row[index]&.value)
        next unless value

        blank = false

        row_data[label] = value if label
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
