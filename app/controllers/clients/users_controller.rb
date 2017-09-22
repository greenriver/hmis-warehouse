module Clients
  class UsersController < Window::Clients::UsersController
    include ClientPathGenerator
    
    def client_scope
      client_source.destination
    end
  
  end
end
