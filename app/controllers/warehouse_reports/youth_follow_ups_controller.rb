###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class YouthFollowUpsController < ApplicationController
    include WarehouseReportAuthorization
    include ClientPathGenerator
    def index
      @end_date = report_params.dig(:filter, :end)&.to_date || Date.current
      @report = GrdaWarehouse::WarehouseReports::Youth::FollowUpsReport.new(@end_date, user: current_user)
    end

    private def report_params
      params.permit(
        filter:
          [
            :end,
          ],
      )
    end
  end
end
