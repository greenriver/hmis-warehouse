###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Provides client details such as personal ID's
module Api
  class ClientsController < ApplicationController
    include ClientShowPages
    before_action :set_client

    def show
      @source_client_details = @client.source_clients.
        source_visible_to(current_user).to_a
      current_user.policy_context.preload_client_dependencies(@source_client_details.map(&:id))
      log_destination_client
      render layout: false
    end

    private def set_client
      @client = GrdaWarehouse::Hud::Client.destination_visible_to(current_user).
        find_by(id: params['id'])
      return unless @client.blank?

      @client = GrdaWarehouse::Hud::Client.source_visible_to(current_user).
        find(params['id']).
        destination_client || raise(ActiveRecord::RecordNotFound)
    end

    # The Audit tab lists rows by destination client_id, and a drilldown may pass a source id.
    private def log_destination_client
      log_item(@client)
      @activity.item_id = @client.id
      @activity.client_id = @client.id
    end
  end
end
