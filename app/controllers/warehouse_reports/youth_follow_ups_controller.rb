###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module WarehouseReports
  class YouthFollowUpsController < ApplicationController
    include WarehouseReportAuthorization
    include ClientPathGenerator
    def index
      @end_date = report_params.dig(:filter, :end)&.to_date || Date.current
      @report = GrdaWarehouse::WarehouseReports::Youth::FollowUpsReport.new(@end_date, user: current_user)
      current_user.policy_context.preload_client_dependencies(@report.clients.map { |client| client[:id] })
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
