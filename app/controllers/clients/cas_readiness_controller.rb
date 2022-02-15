###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Clients
  class CasReadinessController < ApplicationController
    include ClientPathGenerator
    include ClientDependentControllers

    before_action :require_can_edit_clients!
    before_action :set_client
    after_action :log_client

    def edit
      @neighborhoods = Cas::Neighborhood.order(:name).pluck(:id, :name) if Cas::Neighborhood.db_exists?
    end

    def update
      update_params = cas_readiness_params
      if GrdaWarehouse::Config.get(:cas_flag_method).to_s != 'file'
        update_params[:disability_verified_on] = (@client.disability_verified_on || Time.now if update_params[:disability_verified_on] == '1')
      end

      if @client.update(update_params)
        # Keep various client fields in sync with files if appropriate
        @client.sync_cas_attributes_with_files
        # Maintain the veteran status
        @client.adjust_veteran_status

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
      @client = destination_searchable_client_scope.find(params[:client_id].to_i)
    end

    def cas_readiness_params
      params.require(:readiness).permit(*client_source.cas_readiness_parameters)
    end

    def title_for_show
      "#{@client.name} - CAS Readiness"
    end
  end
end
