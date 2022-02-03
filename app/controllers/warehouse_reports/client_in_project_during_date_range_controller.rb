###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class ClientInProjectDuringDateRangeController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    def index
      @start = (params.try(:[], :project).try(:[], :start) || oct_1).to_date
      @end   = (params.try(:[], :project).try(:[], :end) || nov_30).to_date
      if params[:project].blank?
        @project = project_source.first
        @project_id = @project.id
      else
        @project_id = params[:project][:id].to_i
        @project = project_source.find_by(id: @project_id)
      end
      @enrollments = @project.service_history_enrollments.entry.
        open_between(start_date: @start, end_date: @end).
        joins(:client).
        preload(:client).
        distinct.
        select(:client_id)
      @clients = client_source.where(id: @enrollments).order(:LastName, :FirstName)

      respond_to do |format|
        format.html do
          @clients = @clients.page(params[:page]).per(25)
        end
        format.xlsx do
          @clients
        end
      end
    end

    # AHAR reporting dates
    private def oct_1
      @oct_1 ||= begin
        d1 = Date.current
        d2 = "#{d1.year - 1}-10-01".to_date
        d2 -= 1.year while d2 + 1.year - 1.day > d1
        d2
      end
    end

    private def nov_30
      oct_1 + 1.year - 1.day
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    private def project_source
      GrdaWarehouse::Hud::Project.viewable_by(current_user)
    end

    private def service_history_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end
  end
end
