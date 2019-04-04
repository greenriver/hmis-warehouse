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