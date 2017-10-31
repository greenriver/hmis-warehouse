module Window::Clients
  class HistoryController < ApplicationController
    include WindowClientPathGenerator
    
    before_action :require_can_see_this_client_demographics!
    before_action :set_client, :check_release
    
    def show
      
    end
    
    def set_client
      @client = client_scope.find(params[:client_id].to_i)
    end
    alias_method :set_client_from_client_id, :set_client
    
    def client_source
      GrdaWarehouse::Hud::Client
    end
    
    def client_scope
      client_source.destination.
        joins(source_clients: :data_source).
        where(data_sources: {visible_in_window: true})
    end
  end
end
