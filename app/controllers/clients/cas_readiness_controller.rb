module Clients
  class CasReadinessController < ApplicationController
    include ClientPathGenerator
    
    before_action :require_can_edit_clients!
    before_action :set_client

    def edit

    end
    
    def update
      update_params = cas_readiness_params
      update_params[:disability_verified_on] = if update_params[:disability_verified_on] == '1'
        @client.disability_verified_on || Time.now
      else
        nil
      end
      if update_params[:housing_release_status].present?
        update_params[:housing_assistance_network_released_on] = @client.housing_assistance_network_released_on || Time.now
      else
        update_params[:housing_assistance_network_released_on] = nil
      end
      if @client.update(update_params)
        flash[:notice] = 'Client updated'
        ::Cas::SyncToCasJob.perform_later
        redirect_to action: :edit
      else
        flash[:notice] = 'Unable to update client'
        render :edit
      end
    end

    protected

      def set_client
        @client = client_source.destination.find(params[:client_id].to_i)
      end

      def cas_readiness_params
        params.require(:readiness).permit(*client_source.cas_readiness_parameters)
      end

      def client_source
        GrdaWarehouse::Hud::Client
      end
  end
end
