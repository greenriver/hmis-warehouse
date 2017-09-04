module Window
  class SourceClientsController < ApplicationController
    include PjaxModalController
    include WindowClientPathGenerator
    before_action :require_can_create_clients!
    before_action :set_client
    before_action :set_destination_client

    def edit

    end

    def update
      if @client.update!(client_params)
        # also update the destination client, we're assuming this is authoritative 
        # for this bit of data
        @destination_client.update(client_params)
        flash[:notice] = "Client saved successfully"
        client_source.clear_view_cache(@destination_client.id)
      else
        flash[:error] = 'Unable to save client'
      end
      redirect_to redirect_to_path
    end

    def redirect_to_path
      window_client_path(@destination_client)
    end

    def set_client
      @client = client_source.find(params[:id].to_i)
    end

    def set_destination_client
      @destination_client = @client.destination_client
    end

    def client_params
      params.require(:client).
        permit(
          :SSN,
          :DOB,
          :FirstName,
          :MiddleName,
          :LastName,
          :Gender,
          :VeteranStatus
        )
    end
    def client_source
      GrdaWarehouse::Hud::Client
    end
  end
end