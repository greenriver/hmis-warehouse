module Clients
  class EtoApiController < Window::Clients::EtoApiController
    include ClientPathGenerator
    
    def client_scope
      client_source.destination.joins(source_clients: :data_source)
    end
  
  end
end
