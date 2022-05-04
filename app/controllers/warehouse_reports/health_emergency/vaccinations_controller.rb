###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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

      source_clients = GrdaWarehouse::WarehouseClient.where(destination_id: vaccination_scope.select(:client_id))
      with_service = GrdaWarehouse::ServiceHistoryEnrollment.
        joins(:project).
        service_within_date_range(start_date: @filter.start, end_date: Date.current).
        where(client_id: vaccination_scope.select(:client_id)).
        merge(GrdaWarehouse::Hud::Project.where(id: project_ids))

      @clients = GrdaWarehouse::Hud::Client.
        distinct.
        destination_visible_to(current_user, source_client_ids: source_clients.pluck(:source_id)).
        where(id: with_service.distinct.select(:client_id)).
        order(sort_order).
        preload(:processed_service_history, :service_history_enrollments, :health_emergency_vaccinations)
      respond_to do |format|
        format.html do
          @pagy, @clients = pagy(@clients)
        end
        format.xlsx do
        end
      end
    end

    private def default_start_date
      3.weeks.ago.to_date
    end

    private def project_ids
      @filter.effective_project_ids_from_projects.presence || GrdaWarehouse::Hud::Project.residential.pluck(:id)
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
