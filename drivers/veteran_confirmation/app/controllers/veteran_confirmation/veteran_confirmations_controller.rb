###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module VeteranConfirmation
  class VeteranConfirmationsController < ApplicationController
    before_action :require_can_view_clients!
    before_action :set_client

    def show
      @client.check_va_veteran_status(user: current_user)

      redirect_to client_path(@client.id)
    end

    private def set_client
      @client = ::GrdaWarehouse::Hud::Client.destination_visible_to(current_user).
        find_by(id: params[:id])
    end
  end
end
