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

    def index
      @html = true
      @results = test_scope.tested_within_range(@filter.range).
        joins(client: [:processed_service_history, service_history_services: :service_history_enrollment]).
        preload(client: [:processed_service_history, service_history_services: :service_history_enrollment])

      if @filter.effective_project_ids_from_projects.present?
        @results = @results.merge(
          GrdaWarehouse::ServiceHistoryEnrollment.
            joins(:project).
            service_within_date_range(start_date: @filter.start, end_date: Date.current).
            merge(GrdaWarehouse::Hud::Project.where(id: project_ids)),
        )
      else
        @results = @results.merge(
          GrdaWarehouse::ServiceHistoryEnrollment.
            joins(:project).
            merge(GrdaWarehouse::Hud::Project.where(id: project_ids)),
        )
      end
      respond_to do |format|
        format.html do
          @results = @results.distinct.
            page(params[:page]).
            per(25)
        end
        format.xlsx do
          @results = @results.distinct
        end
      end
    end

    private def test_scope
      GrdaWarehouse::HealthEmergency::Test.visible_to(current_user).newest_first
    end

    def report_index
      warehouse_reports_health_emergency_testing_results_path
    end
    helper_method :report_index
  end
end
