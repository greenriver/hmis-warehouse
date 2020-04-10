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

    private def test_scope
      GrdaWarehouse::HealthEmergency::Test.visible_to(current_user).newest_first
    end

    def report_index
      warehouse_reports_health_emergency_testing_results_path
    end
    helper_method :report_index
  end
end
