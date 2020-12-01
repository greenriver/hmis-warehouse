###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
module ClaimsReporting::WarehouseReports
  class PerformanceController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_view_member_health_reports!

    def index
    end
  end
end
