module Clients
  class MonthOfServiceController < Window::Clients::MonthOfServiceController
    include ClientPathGenerator
    
    
        
    def client_scope
      client_source.destination.joins(source_clients: :data_source)
    end

    def project_scope
      project_source
    end

    def service_history_service_scope
      GrdaWarehouse::ServiceHistory.all
    end
  
  end
end
