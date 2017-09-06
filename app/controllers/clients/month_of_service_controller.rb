module Clients
  class MonthOfServiceController < Window::Clients::MonthOfServiceController
    include ClientPathGenerator
    
    
        
    def client_scope
      client_source.destination.joins(source_clients: :data_source)
    end

    def project_scope
      project_source
    end
  
  end
end
