###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports
  class YouthExportController < ApplicationController
    def index
      filter_params = { user_id: current_user.id }
      filter_params.merge!(report_params[:filter]) if report_params[:filter].present?
      @filter = ::Filters::DateRangeAndSources.new(filter_params)
      @report = GrdaWarehouse::WarehouseReports::Youth::Export.new(@filter)

      respond_to do |format|
        format.html do
          @clients = @report.clients.page(params[:page]).per(25)
        end
        format.xlsx do
          render xlsx: :index, filename: "Youth Export #{Time.current.to_s.delete(',')}.xlsx"
        end
      end
    end

    private def report_params
      params.permit(
        filter: [
          :start,
          :end,
          project_ids: [],
          organization_ids: [],
          data_source_ids: [],
          cohort_ids: [],
        ],
      )
    end
  end
end
