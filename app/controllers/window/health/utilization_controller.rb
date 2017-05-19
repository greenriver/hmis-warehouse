module Window
  class HealthController < ApplicationController
    before_action :can_edit_client_health!
    before_action :set_client, only: [:index]
    
    def index
      
      
    end

    def show
    end


    protected def set_client
      @client = GrdaWarehouse::Hud::Client.find(params[:client_id].to_i)
    end
  end
end