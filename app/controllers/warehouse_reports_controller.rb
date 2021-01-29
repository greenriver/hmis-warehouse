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
    report_definitions = current_user.reports
    report_definitions = report_definitions.select { |r| r.health == false } unless GrdaWarehouse::Config.get(:healthcare_available)
    report_definitions = report_definitions.group_by(&:report_group)
    @report_definitions = report_definitions.to_a.sort_by { |group, _| group }
  end
end
