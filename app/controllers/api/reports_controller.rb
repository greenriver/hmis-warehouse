###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Api
  class ReportsController < ApplicationController
    def favorite
      currently_favorited = current_user.favorite_reports.exists?(params[:id])

      if request.put? && !currently_favorited
        report = GrdaWarehouse::WarehouseReports::ReportDefinition.find(params[:id])
        current_user.favorite_reports << report
      elsif request.delete? && currently_favorited
        report = GrdaWarehouse::WarehouseReports::ReportDefinition.find(params[:id])
        current_user.favorite_reports.delete(report)
      end
    end
  end
end
