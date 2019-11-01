###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Clients
  class EtoApiController < ApplicationController
    include ClientPathGenerator

    before_action :require_can_view_client_window!
    before_action :set_client
    after_action :log_client

    def show
      render json: @client.api_status
    end

    def update
      session[:return_to] ||= request.referer
      @client.update_via_api
      redirect_to session.delete(:return_to)
    end

    def set_client
      @client = client_scope.find(params[:client_id].to_i)
    end

    def client_source
      GrdaWarehouse::Hud::Client
    end

    def client_scope
      client_source.destination.where(
        client_source.arel_table[:id].in(
          Arel.sql(
            GrdaWarehouse::WarehouseClient.joins(:source).
              merge(GrdaWarehouse::Hud::Client.searchable_by(current_user)).
              select(:destination_id).to_sql,
          ),
        ).
        or(
          client_source.arel_table[:id].in(Arel.sql(GrdaWarehouse::Hud::Client.searchable_by(current_user).select(:id).to_sql)),
        ),
      )
    end
  end
end
