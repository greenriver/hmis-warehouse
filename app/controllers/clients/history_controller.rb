module Clients
  class HistoryController < Window::Clients::HistoryController
    include ClientPathGenerator
    
    skip_before_action :check_release
    before_action :require_can_view_client_and_history!
    
        
    def client_scope
      client_source.destination.joins(source_clients: :data_source)
    end
  
  end
end
