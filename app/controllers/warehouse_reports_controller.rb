###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class WarehouseReportsController < ApplicationController
  include WarehouseReportAuthorization
  # This page just lists the available reports, each report is responsible for access
  skip_before_action :report_visible?
  def index
    # Hide Health if not enabled
    all_report_definitions = if GrdaWarehouse::Config.get(:healthcare_available)
      GrdaWarehouse::WarehouseReports::ReportDefinition.
        enabled.
        ordered.
        group_by(&:report_group)
    else
      GrdaWarehouse::WarehouseReports::ReportDefinition.
        enabled.
        non_health.
        ordered.
        group_by(&:report_group)
    end

    if current_user.can_view_all_reports?
      report_definitions = all_report_definitions
    else
      report_definitions = current_user.reports.group_by(&:report_group)
    end
    @report_definitions = report_definitions.to_a.sort_by { |group, _| group }
  end
end
