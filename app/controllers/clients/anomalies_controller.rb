###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Clients
  class AnomaliesController < ApplicationController
    include ClientDependentControllers

    before_action :require_can_track_anomalies!
    before_action :set_anomaly, only: [:edit, :update, :destroy]
    before_action :set_client
    after_action :log_client

    def index
      @anomalies = @client.anomalies.order(updated_at: :desc).group_by(&:status)
    end

    def edit
    end

    def update
      @anomaly.update(anomaly_params)
      NotifyUser.anomaly_updated(
        client_id: @client.id,
        user_id: current_user.id,
        involved_user_ids: @anomaly.involved_user_ids,
        anomaly_id: @anomaly.id,
      ).deliver_later(priority: -5)
      respond_with(@anomaly, location: client_anomalies_path(client_id: @client.id, anchor: @anomaly.status))
    end

    def create
      @anomaly = @client.anomalies.build(
        anomaly_params.merge(
          status: :new,
          submitted_by: current_user.id,
        ),
      )
      @anomaly.save
      NotifyUser.anomaly_identified(
        client_id: @client.id,
        user_id: current_user.id,
      ).deliver_later(priority: -5)
      respond_with(@anomaly, location: client_anomalies_path(client_id: @client.id, anchor: :new))
    end

    def destroy
    end

    def set_anomaly
      @anomaly = anomaly_scope.find(params[:id].to_i)
    end

    def set_client
      @client = destination_searchable_client_scope.find(params[:client_id].to_i)
    end

    def anomaly_scope
      GrdaWarehouse::Anomaly
    end

    def flash_interpolation_options
      { resource_name: 'Issue' }
    end

    protected def title_for_show
      "#{@client.name} - Anomalies"
    end

    private def anomaly_params
      params.require(:anomaly).
        permit(
          :status,
          :description,
        )
    end
  end
end
