module Clients
  class CasReadinessController < ApplicationController
    include ClientPathGenerator
    
    before_action :require_can_edit_clients!
    before_action :set_client

    def edit

    end
    
    def update
      update_params = cas_readiness_params
      if GrdaWarehouse::Config.get(:cas_flag_method).to_s != 'file'
        update_params[:disability_verified_on] = if update_params[:disability_verified_on] == '1'
          @client.disability_verified_on || Time.now
        else
          nil
        end
      end
      
      if @client.update(update_params)
        # Keep various client fields in sync with files if appropriate
        @client.sync_cas_attributes_with_files
        
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
