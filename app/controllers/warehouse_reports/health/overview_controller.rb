###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Health
  class OverviewController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_view_member_health_reports!

    helper HealthOverviewHelper

    def index
    end
  end
end
