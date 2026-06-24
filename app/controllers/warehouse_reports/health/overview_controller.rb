###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module WarehouseReports::Health
  class OverviewController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_view_member_health_reports!

    helper HealthOverviewHelper

    def index
    end
  end
end
