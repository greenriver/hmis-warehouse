###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Financial
  class ClientsController < ApplicationController
    include ClientPathGenerator # to support tabbed navigation
    include ClientShowPages # to support client_js and rollups
    include ClientDependentControllers

    before_action :require_can_see_this_client_demographics!
    before_action :set_client
    after_action :log_client, only: [:show]

    def show
    end

    def rollup
      @client = client_scope(id: params[:client_id].to_i)&.first
      allowed_rollups = [
        '/financial/clients/rollup/financial_clients',
        '/financial/clients/rollup/financial_transactions',
      ]
      rollup = allowed_rollups.detect do |m|
        partial = params.require(:partial).underscore
        m == '/financial/clients/rollup/' + partial
      end

      raise 'Rollup not in allowlist' unless rollup.present?

      render partial: rollup, layout: false
    end

    private def client_source
      ::GrdaWarehouse::Hud::Client
    end

    private def client_scope(id: nil)
      source_client_ids = ::GrdaWarehouse::WarehouseClient.where(destination_id: id).pluck(:source_id).presence
      client_source.destination_visible_to(current_user, source_client_ids: source_client_ids).where(id: id)
    end

    private def set_client
      @client = client_scope(id: params[:id].to_i)&.first
    end
  end
end
