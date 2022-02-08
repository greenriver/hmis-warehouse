###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Health
  class ExpiringItemsController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_view_aggregate_health!

    helper HealthOverviewHelper

    def index
      @report = Health::ExpiringItemReport.new
    end
  end
end
