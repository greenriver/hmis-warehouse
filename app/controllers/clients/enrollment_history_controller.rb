module Clients
  class EnrollmentHistoryController < ApplicationController
    include ClientPathGenerator
    
    before_action :require_can_edit_clients!
    before_action :set_client

    def index
      @date = params[:history][:date].to_date rescue Date.yesterday
      @histories = history_scope.where(on: @date)
      @available_dates =history_scope.distinct.order(on: :desc).pluck(:on)
    end

    private
    def set_client
      @client = client_source.destination.find(params[:id].to_i)
    end
    def client_source
      GrdaWarehouse::Hud::Client
    end
    def history_source
      GrdaWarehouse::EnrollmentChangeHistory
    end
    def history_scope
      history_source.where(client_id: @client.id)
    end

  end
end