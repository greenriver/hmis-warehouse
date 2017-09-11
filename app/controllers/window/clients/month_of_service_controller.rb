module Window::Clients
  class MonthOfServiceController < ApplicationController
    include WindowClientPathGenerator
    
    before_action :require_can_view_client_window!
    before_action :set_client
    
    def show
      if params[:start].present?
        @start = params[:start].to_date
      else
        @start = @client.date_of_first_service.beginning_of_month
      end
  
      @days = @client.service_dates_for_display(
        service_scope: service_history_service_scope,
        start_date: @start
      )
      @programs = project_scope.preload(:organization).distinct.group_by{|m| [m.data_source_id, m.ProjectID]}
      # Prevent layout over ajax
      render layout: !request.xhr?
    end
    
    def set_client
      @client = client_scope.find(params[:client_id].to_i)
    end
    
    def client_source
      GrdaWarehouse::Hud::Client
    end
    
    def client_scope
      client_source.destination.joins(source_clients: :data_source).where(data_sources: {visible_in_window: true})
    end

    def project_source
      GrdaWarehouse::Hud::Project
    end

    def project_scope
      project_source.joins(:data_source).where(data_sources: {visible_in_window: true})
    end

    def service_history_service_scope
      GrdaWarehouse::ServiceHistory.visible_in_window
    end
  end
end
