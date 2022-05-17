###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class AccessLogs::Report < OpenStruct
  include ArelHelper
  attr_accessor :filter

  def self.viewable_by(user)
    GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
      viewable_by(user).exists?
  end

  def self.url
    'access_logs/warehouse_reports/reports'
  end

  def filter # rubocop:disable Lint/DuplicateMethods
    self[:filter]
  end

  def data
    warehouse_csv = ActivityLog.as_csv(user_id: filter.user_id, range: filter.range)
    {
      'Warehouse' => warehouse_csv,
    }
  end
end
