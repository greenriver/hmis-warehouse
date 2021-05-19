###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientLocationHistory
  class ClientsController < ApplicationController
    include ClientController
    include ClientPathGenerator
    before_action :require_can_view_clients!
    before_action :require_can_view_client_locations!
    before_action :set_client

    def map
    end

    private def client_source
      ::GrdaWarehouse::Hud::Client
    end

    private def client_scope(id: nil)
      client_source.destination_visible_to(current_user).where(id: id)
    end
  end
end
