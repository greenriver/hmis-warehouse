###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ClaimsReporting::WarehouseReports
  class PerformanceController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_view_member_health_reports!

    def index
      @report = ClaimsReporting::PerformanceReport.new
      @report.attributes = params.fetch(:f, {}).permit(@report.available_filters).to_h
    end
  end
end
