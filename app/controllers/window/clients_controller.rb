module Window
  class ClientsController < ApplicationController
    include PjaxModalController
    include ClientController
    
    before_action :require_can_view_client_window!
    before_action :set_client, only: [:show]
    
    def index
      # search
      @clients = if params[:q].present?
        client_source.text_search(params[:q])
      else
        client_scope.none
      end
      sort_filter_index()
      
    end

    def show
      log_item(@client)
    end

    private def client_source
      GrdaWarehouse::Hud::Client
    end

    private def client_scope
      client_source
    end
  end
end