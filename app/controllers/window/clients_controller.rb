module Window
  class ClientsController < ApplicationController
    include PjaxModalController
    include ClientController
    include WindowClientPathGenerator
    
    before_action :require_can_view_client_window!
    before_action :set_client, :check_release, only: [:show]
    before_action :set_client_from_client_id, only: [:image, :rollup]
    before_action :require_can_create_clients!, only: [:new, :create]

    def index
      # search
      @clients = if params[:q].present?
        client_source.text_search(params[:q], client_scope: client_search_scope)
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
      client_source.joins(source_clients: :data_source).where(data_sources: {visible_in_window: true})
    end

    def client_search_scope
      client_source.source.joins(:data_source).where(data_sources: {visible_in_window: true})
    end

    def set_client_from_client_id
      @client = client_source.find(params[:client_id].to_i)
    end

    def user_can_view_confidential_names?
      false
    end

  end
end
