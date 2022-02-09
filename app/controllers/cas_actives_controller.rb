###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class CasActivesController < ApplicationController
  before_action :require_can_edit_clients!
  before_action :set_client

  def update
    if @client.update(sync_with_cas: false)
      render status: 200, json: 'Client will no longer sync with CAS'.to_json, layout: false
    else
      render status: 500, json: 'Failed to update client'.to_json, layout: false
    end
  end

  def set_client
    @client = client_source.find(params[:id].to_i)
  end

  def client_source
    GrdaWarehouse::Hud::Client
  end

  def update_params
    params.require(:cas_active)
  end
end
