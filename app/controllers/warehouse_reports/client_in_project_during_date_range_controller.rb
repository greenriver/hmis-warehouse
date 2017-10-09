module WarehouseReports
  class ClientInProjectDuringDateRangeController < ApplicationController
    before_action :require_can_view_reports!
    def index
      @start = ( project_params[:start] || oct_1  ).to_date
      @end   = ( project_params[:end]   || nov_30 ).to_date
      if params[:project].blank?
        @project = project_source.first
        @project_id = [@project.ProjectID, @project.data_source_id]
      else
        @project_id = JSON.parse(project_params[:id])
        @project = project_source.where(ProjectID: @project_id.first, data_source_id: @project_id.last).first
      end

      @project = project_source.where(ProjectID: @project_id.first, data_source_id: @project_id.last).first

      st = service_history_source.arel_table
      @clients = client_source.where(
        id: service_history_source.
              where( project_id: @project.ProjectID, data_source_id: @project.data_source_id ).
              where( st[:date].gteq @start ).
              where( st[:date].lteq @end ).
              select(:client_id).
              distinct
      )
      @clients.joins(:enrollments)
      @clients = @clients.page(params[:page]).per(25)
     
    end

    def project_params
      params.require(:project).permit(
        :id,
        :start,
        :end
      )
    end

    def available_projects
      project_source.joins(:data_source).merge(GrdaWarehouse::DataSource.order(:short_name)).order(:ProjectName).pluck(:ProjectName, :ProjectID, :data_source_id, :short_name).map do |name,id,ds_id,short_name|
        ["#{name} - #{short_name}", [id,ds_id]]
      end
    end
    helper_method :available_projects
        
    # AHAR reporting dates
    private def oct_1
      @oct_1 ||= begin
        d1 = Date.today
        d2 = "#{ d1.year - 1 }-10-01".to_date
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
      GrdaWarehouse::Hud::Project  
    end

    private def service_history_source
      GrdaWarehouse::ServiceHistory.service
    end
  end
end