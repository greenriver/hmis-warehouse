module Clients
  class UsersController < Window::Clients::UsersController
    include ClientPathGenerator
    before_action :require_can_assign_users_to_clients!
    after_action :log_client
    
    def client_scope
      client_source.destination
    end  
  end
end
