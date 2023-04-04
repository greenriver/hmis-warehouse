###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class AccessLogs::Report < OpenStruct
  include ArelHelper
  include Rails.application.routes.url_helpers
  attr_accessor :filter
  attr_writer :cas_user_id

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
    {
      'Warehouse' => ActivityLog.to_a(user_id: filter.user_id, range: filter.range),
      'CAS' => CasAccess::ActivityLog.to_a(user_id: @cas_user_id, range: filter.range),
    }
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
