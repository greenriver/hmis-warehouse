###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class WarehouseReportsController < ApplicationController
  include WarehouseReportAuthorization
  # This page just lists the available reports, each report is responsible for access
  skip_before_action :report_visible?
  def index
    report_definitions = current_user.reports.order(name: :asc)
    report_definitions = report_definitions.select { |r| r.health == false } unless GrdaWarehouse::Config.get(:healthcare_available)
    report_definitions = report_definitions.group_by(&:report_group)
    @report_definitions = report_definitions.to_a.sort_by { |group, _| group }
    recent_reports_paths = current_user.activity_logs.
      warehouse_reports.
      created_in_range(range: 1.weeks.ago..Time.current).
      order(created_at: :desc).
      pluck(:path).map { |u| u.split('?').first }.uniq.first(10)
    @recent_reports = report_definitions.values.flatten.select do |r|
      "/#{r.url}".in?(recent_reports_paths)
    end
  end
end
