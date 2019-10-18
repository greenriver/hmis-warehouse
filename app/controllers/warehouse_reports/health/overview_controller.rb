###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports::Health
  class OverviewController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_view_aggregate_health!

    helper HealthOverviewHelper

    def index
    end
  end
end
