###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

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
