###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class ClientLookupsController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper

    def index
      respond_to do |format|
        format.html {}
        format.xlsx do
          @start_date = report_params[:start_date].to_date
          @end_date = report_params[:end_date].to_date
          @project_ids = report_params[:project_ids].reject(&:blank?)

          @clients = client_source.
            joins(:service_history_enrollments).
            preload(:source_clients).
            merge(GrdaWarehouse::ServiceHistoryEnrollment.
              open_between(start_date: @start_date, end_date: @end_date).
              in_project(@project_ids)).
            distinct
          render xlsx: 'report', filename: 'client_lookups.xlsx'
        end
      end
    end

    private def report_params
      return nil unless params[:report].present?

      params.require(:report).
        permit(
          :start_date,
          :end_date,
          project_ids: [],
        )
    end

    private def report_columns
    end

    def available_projects
      project_source.pluck(:ProjectName, :id).to_h
    end
    helper_method :available_projects

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end
  end

  private def project_source
    GrdaWarehouse::Hud::Project.viewable_by(current_user)
  end
end
