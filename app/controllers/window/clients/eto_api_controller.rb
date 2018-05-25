module Window::Clients
  class EtoApiController < ApplicationController
    include WindowClientPathGenerator
    
    before_action :require_can_view_client_window!
    before_action :set_client
    
    def show
      render json: @client.api_status
    end

    def update
      session[:return_to] ||= request.referer
      @client.update_via_api
      redirect_to session.delete(:return_to)
    end
    
    def set_client
      @client = client_scope.find(params[:client_id].to_i)
    end
    
    def client_source
      GrdaWarehouse::Hud::Client
    end
    
    def client_scope
      client_source.destination.joins(source_clients: :data_source).merge(GrdaWarehouse::DataSource.visible_in_window_to(current_user))
    end
  end
end
