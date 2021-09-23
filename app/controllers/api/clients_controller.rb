###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Provides client details such as personal ID's
module Api
  class ClientsController < ApplicationController
    include ClientShowPages
    before_action :set_client

    def show
      @source_client_details = @client.source_clients.
        source_visible_to(current_user)
      render layout: false
    end

    def set_client
      @client = GrdaWarehouse::Hud::Client.destination_visible_to(current_user).
        find_by(id: params['id'])
      return unless @client.blank?

      @client = GrdaWarehouse::Hud::Client.source_visible_to(current_user).
        find(params['id'])&.
        destination_client
    end
  end
end
