###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Assigned
  class ClientsController < ApplicationController
    include ClientPathGenerator

    before_action :require_can_search_window!
    before_action :set_user

    def index
      @user_clients = @user.user_clients.
        joins(:client).
        merge(GrdaWarehouse::UserClient.active)
      if can_view_clients?
        @client_path = :client_path
      elsif can_search_window?
        @client_path = :window_client_path
      end
    end

    def set_user
      @user = current_user
    end
  end
end
