###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class IncomesController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization

    def index
      filter_params = { user_id: current_user.id }
      filter_params.merge!(report_params[:filter]) if report_params[:filter].present?
      @filter = ::Filters::DateRangeAndSources.new(filter_params)

      @start_date = @filter.start
      @end_date = @filter.end

      @enrollments = enrollment_source.
        open_between(start_date: @start_date, end_date: @end_date).
        in_project(@filter.effective_project_ids).
        joins(:client, :enrollment).
        order(first_date_in_program: :asc)

      respond_to do |format|
        format.html do
          @enrollments = @enrollments.page(params[:page].to_i).per(25)
        end
        format.xlsx do
          require_can_view_clients!
        end
      end
    end

    private def report_params
      params.permit(
        filter: [
          :start,
          :end,
          project_ids: [],
          project_group_ids: [],
          organization_ids: [],
          data_source_ids: [],
        ],
      )
    end

    private def enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment.
        entry.
        merge(GrdaWarehouse::Hud::Project.viewable_by(current_user))
    end
  end
end
