module Assigned
  class ClientsController < ApplicationController

    before_action :require_can_search_window!
    before_action :set_user

    def index
      @user_clients = @user.user_clients.joins(:client)
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