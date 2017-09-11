module Clients
  class HistoryController < Window::Clients::HistoryController
    include ClientPathGenerator
    
    
        
    def client_scope
      client_source.destination.joins(source_clients: :data_source)
    end
  
  end
end
