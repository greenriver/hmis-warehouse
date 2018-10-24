module Window
  class PrintController < ApplicationController
    before_action :require_can_view_client_window!
    before_action :set_client, only: [:index]
    after_action :log_client
    
    def index
      
      
    end

    def show
    end


    protected def set_client
      @client = GrdaWarehouse::Hud::Client.find(params[:client_id].to_i)
    end
  end
end