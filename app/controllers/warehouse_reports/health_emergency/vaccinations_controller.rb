###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::HealthEmergency
  class VaccinationsController < ApplicationController
    include ArelHelper
    include AjaxModalRails::Controller
    include WarehouseReportAuthorization
    include WarehouseReportsHealthEmergencyController
    before_action :require_can_see_health_emergency_clinical!

    def index
      @html = true
      vaccinations = vaccination_scope.vaccinated_within_range(@filter.range).
        joins(client: [:processed_service_history, :service_history_enrollments])

      if @filter.effective_project_ids_from_projects.present?
        vaccinations = vaccinations.merge(
          GrdaWarehouse::ServiceHistoryEnrollment.
            joins(:project).
            service_within_date_range(start_date: @filter.start, end_date: Date.current).
            merge(GrdaWarehouse::Hud::Project.where(id: project_ids)),
        )
      else
        vaccinations = vaccinations.merge(
          GrdaWarehouse::ServiceHistoryEnrollment.
            joins(:project).
            merge(GrdaWarehouse::Hud::Project.where(id: project_ids)),
        )
      end

      @clients = GrdaWarehouse::Hud::Client.
        distinct.
        destination_visible_to(current_user).
        where(id: vaccinations.select(:client_id)).
        order(sort_order).
        preload(:processed_service_history, :service_history_enrollments, :health_emergency_vaccinations)
      respond_to do |format|
        format.html do
          @clients = @clients.
            page(params[:page]).
            per(25)
        end
        format.xlsx do
        end
      end
    end

    private def sort_options
      {
        name: 'Name',
        # created_at: 'Date Added',
        # tested_on: 'Test Date',
      }
    end
    helper_method :sort_options

    private def sort_order
      case selected_sort
      when :created_at
        { created_at: :desc }
      when :tested_on
        { tested_on: :desc }
      else
        [c_t[:LastName].asc, c_t[:FirstName].asc]
      end
    end

    private def vaccination_scope
      GrdaWarehouse::HealthEmergency::Vaccination.visible_to(current_user)
    end

    def report_index
      warehouse_reports_health_emergency_vaccinations_path
    end
    helper_method :report_index
  end
end
