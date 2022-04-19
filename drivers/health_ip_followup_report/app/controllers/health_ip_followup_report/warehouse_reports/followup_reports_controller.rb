###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthIpFollowupReport::WarehouseReports
  class FollowupReportsController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_view_aggregate_health!

    def index
      @end_date = report_params[:end_date]&.to_date || Date.today
      @start_date = report_params[:start_date]&.to_date || @end_date - 3.months
      @report = ::HealthIpFollowupReport::FollowupsReport.new(start_date: @start_date, end_date: @end_date)
    end

    def report_params
      return {} unless params[:report]

      params.require(:report).
        permit(
          :start_date,
          :end_date,
        )
    end
  end
end
