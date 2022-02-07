###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Assigned
  class ClientsController < ApplicationController
    include ClientPathGenerator

    before_action :require_can_view_clients!
    before_action :set_user

    def index
      @user_clients = @user.user_clients.
        joins(:client).
        merge(GrdaWarehouse::UserClient.active)
      @client_path = :client_path
    end

    def set_user
      @user = current_user
    end
  end
end
