###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClaimsReporting::WarehouseReports
  class ImportsController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_view_member_health_reports!

    def index
      cols = ClaimsReporting::Import.column_names - ['content']
      @imports = ClaimsReporting::Import.order(created_at: :desc).select(cols)
    end
  end
end
