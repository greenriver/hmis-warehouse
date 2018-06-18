class WarehouseReportsController < ApplicationController
  include WarehouseReportAuthorization
  # This page just lists the available reports, each report is responsible for access
  skip_before_action :report_visible?

    all_report_definitions = GrdaWarehouse::WarehouseReports::ReportDefinition.enabled.
      ordered.
      group_by(&:report_group)
    if current_user.can_view_all_reports?
      @report_definitions = all_report_definitions
    else
      @report_definitions = current_user.reports.group_by(&:report_group)
    end
    @report_definitions = filter_reports(@report_definitions)
  end

  private

  def filter_reports report_definitions
    unless GrdaWarehouse::Config.get(:healthcare_available)
      report_definitions = report_definitions.except('Health')
    end
    report_definitions
  end

end
