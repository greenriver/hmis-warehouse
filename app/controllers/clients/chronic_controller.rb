###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Clients
  class ChronicController < ApplicationController
    include ClientPathGenerator

    before_action :require_can_edit_clients!
    before_action :set_client
    after_action :log_client

    def edit
      @note = GrdaWarehouse::ClientNotes::Base.new
      if params[:date].present?
        @date = params[:date].to_date
      else
        @date = Date.current
      end
    end

    def update
      update_params = chronic_params
      update_params[:disability_verified_on] = (@client.disability_verified_on || Time.now if update_params[:disability_verified_on] == '1')

      if @client.update(update_params)
        flash[:notice] = 'Client updated'
        ::Cas::SyncToCasJob.perform_later
        redirect_to action: :show
      else
        flash[:notice] = 'Unable to update client'
        render :show
      end
    end

    protected

    def set_client
      @client = client_source.destination.find(params[:client_id])
    end

    def cas_readiness_params
      params.require(:readiness).permit(*client_source.cas_readiness_parameters)
    end

    def client_source
      GrdaWarehouse::Hud::Client
    end

    def title_for_show
      "#{@client.name} - Chronic"
    end
  end
end
