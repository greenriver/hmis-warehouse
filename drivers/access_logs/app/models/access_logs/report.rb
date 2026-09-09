###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AccessLogs::Report < OpenStruct
  include ArelHelper
  include Rails.application.routes.url_helpers
  attr_accessor :filter
  attr_writer :cas_user_id, :hmis_user_id

  # Excel allows 1,048,576 rows per sheet; this leaves room for the header and the truncation note.
  EXPORT_ROW_LIMIT = 1_048_000

  def self.viewable_by(user)
    GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
      viewable_by(user).exists?
  end

  def self.url
    'access_logs/warehouse_reports/reports'
  end

  def url
    access_logs_warehouse_reports_reports_url(host: ENV.fetch('FQDN'), protocol: 'https')
  end

  def title
    'User Access Logs Export'
  end

  def filter # rubocop:disable Lint/DuplicateMethods
    self[:filter]
  end

  # Sheet name => Enumerator of rows (header first), or nil for a system whose database is absent.
  # Each enumerator yields one row past the cap so as_excel can tell a full sheet from a truncated one.
  def sheet_rows
    fetch_limit = EXPORT_ROW_LIMIT + 1
    sheets = {
      'Warehouse' => ActivityLog.export_rows(user_id: filter.user_id, range: export_range, limit: fetch_limit),
      'CAS' => CasAccess::ActivityLog.export_rows(user_id: @cas_user_id, range: export_range, limit: fetch_limit),
    }
    sheets['HMIS'] = Hmis::ActivityLog.export_rows(user_id: @hmis_user_id, range: export_range, limit: fetch_limit) if HmisEnforcement.hmis_enabled?
    sheets
  end

  # filter.range is Date..Date; the log tables store UTC instants, so a bare Date upper bound
  # drops evening (Eastern) activity on the last day.
  private def export_range
    filter.start.beginning_of_day..filter.end.end_of_day
  end

  def as_excel
    Axlsx::Package.new do |p|
      wb = p.workbook
      sheet_rows.each do |name, rows|
        next if rows.nil?

        wb.add_worksheet(name: name) { |sheet| write_sheet(sheet, rows) }
      end
    end
  end

  private def write_sheet(sheet, rows)
    title = sheet.styles.add_style(sz: 12, b: true, alignment: { horizontal: :center })
    data_rows = 0
    rows.each_with_index do |row, index|
      if index.zero?
        sheet.add_row(row, style: title)
        next
      end

      if data_rows == EXPORT_ROW_LIMIT
        sheet.add_row(["Only the first #{EXPORT_ROW_LIMIT} rows are included. Narrow the date range or choose a user to export the rest."])
        break
      end

      sheet.add_row(row)
      data_rows += 1
    end
  end
end
