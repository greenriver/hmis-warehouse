###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports
  class YouthIntakesController < ApplicationController

    def index
      @filter = ::Filters::DateRange.new(report_params[:filter])
      @report = GrdaWarehouse::WarehouseReports::Youth::HomelessYouthReport.new(@filter)
    end

    private def report_params
      params.permit(
          filter: [
              :start,
              :end,
          ]
      )
    end

  end
end