###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports::HealthEmergency
  class TestingResultsController < ApplicationController
    include ArelHelper
    include PjaxModalController
    include WarehouseReportAuthorization
    include WarehouseReportsHealthEmergencyController
    before_action :require_can_see_health_emergency_clinical!

    before_action :set_filter

    def index
      project_ids = @filter.effective_project_ids_from_projects.presence || GrdaWarehouse::Hud::Project.viewable_by(current_user).pluck(:id)
      @results = test_scope.tested_within_range(@filter.range).
        joins(client: [:processed_service_history, :service_history_enrollments]).
        merge(
          GrdaWarehouse::ServiceHistoryEnrollment.
            joins(:project).
            service_within_date_range(start_date: @filter.start, end_date: Date.current).
            merge(GrdaWarehouse::Hud::Project.where(id: project_ids)),
        ).
        distinct.
        page(params[:page]).
        per(25)
    end

    def set_filter
      @filter = if filter_params.present?
        ::Filters::DateRangeAndSources.new(filter_params)
      else
        ::Filters::DateRangeAndSources.new
      end
    end

    def filter_params
      return unless params[:filters_date_range_and_sources].present?

      params.require(:filters_date_range_and_sources).permit(
        :start,
        :end,
        project_ids: [],
      )
    end

    def available_locations
      GrdaWarehouse::Hud::Project.viewable_by(current_user).map do |p|
        [
          p.name_and_type,
          p.id,
        ]
      end
    end
    helper_method :available_locations

    private def test_scope
      GrdaWarehouse::HealthEmergency::Test.visible_to(current_user).newest_first
    end
  end
end
