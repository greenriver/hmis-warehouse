module WarehouseReports
  class IncomesController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization

    def index
      @filter = ::Filters::DateRangeAndSources.new(report_params.merge(user_id: current_user.id))

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
          :start,
          :end,
          project_ids: [],
          project_group_ids: [],
          organization_ids: [],
          data_source_ids: [],
      )
    end
  end
end