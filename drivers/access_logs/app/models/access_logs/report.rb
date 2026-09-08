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

  def data
    sheets = {
      'Warehouse' => ActivityLog.to_a(user_id: filter.user_id, range: export_range),
      'CAS' => CasAccess::ActivityLog.to_a(user_id: @cas_user_id, range: export_range),
    }
    sheets['HMIS'] = Hmis::ActivityLog.to_a(user_id: @hmis_user_id, range: export_range) if HmisEnforcement.hmis_enabled?
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
      data.each do |name, data|
        next unless data.present?

        wb.add_worksheet(name: name) do |sheet|
          title = sheet.styles.add_style(sz: 12, b: true, alignment: { horizontal: :center })
          sheet.add_row(data.first, style: title)
          data.drop(1).each do |row|
            sheet.add_row(row)
          end
        end
      end
    end
  end
end
