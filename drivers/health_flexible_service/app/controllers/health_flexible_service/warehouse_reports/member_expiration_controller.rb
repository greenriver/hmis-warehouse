###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthFlexibleService::WarehouseReports
  class MemberExpirationController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_administer_health!
    before_action :set_report

    def index
      respond_to do |format|
        format.html do
          data = @report.data
          @pagy, @patients = pagy(data, items: 50)
        end
        format.xlsx do
          @patients = @report.data
          headers['Content-Disposition'] = "attachment; filename=#{@report.title} Report.xlsx"
        end
      end
    end

    private def set_report
      @report = HealthFlexibleService::MemberExpiration.new
    end
  end
end
