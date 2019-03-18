module WarehouseReports
  class IncomesController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization

    def index
      filter_params = {user_id: current_user.id}
      filter_params.merge!(report_params[:filter]) if report_params[:filter].present?
      @filter = ::Filters::DateRangeAndSources.new(filter_params)

      @start_date = @filter.start
      @end_date = @filter.end

      respond_to do |format|
        format.html {}
        format.xlsx do
          require_can_view_clients!
        end
      end
    end

    def report_params
      params.permit(
        filter: [
            :start,
          :end,
          project_ids: [],
          project_group_ids: [],
          organization_ids: [],
          data_source_ids: [],
        ]
      )
    end
  end
end