###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HeaderKeyedRows
  def row_by_header(headers, rows, key:)
    row = rows.find { |r| r[0] == key }
    raise ArgumentError, "no row whose first cell is #{key.inspect}" if row.nil?
    raise ArgumentError, "#{headers.size} headers but #{row.size} cells -- headers: #{headers.inspect}, row: #{row.inspect}" unless headers.size == row.size

    headers.zip(row).to_h
  end

  def sheet_row_by_header(sheet, key:)
    headers = sheet.row(sheet.first_row)
    rows = ((sheet.first_row + 1)..sheet.last_row).map { |i| sheet.row(i) }
    row_by_header(headers, rows, key: key)
  end
end
