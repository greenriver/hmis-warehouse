###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Clients::AuditsController < ApplicationController
  include ClientPathGenerator
  include ClientDependentControllers
  before_action :require_can_audit_clients!
  before_action :set_client
  after_action :log_client

  def index
    client_id = @client.id
    al_t = ActivityLog.arel_table
    @audit_log = ActivityLog.where(item_model: 'GrdaWarehouse::Hud::Client').
      where(al_t[:path].matches("%clients/#{client_id}/%"). # contains client_id
            or(al_t[:path].matches("%clients/#{client_id}"))). # ends with client_id
      order(created_at: :desc)
    @pagy, @audit_log = pagy(@audit_log, items: 50)
  end

  protected

  def set_client
    @client = destination_searchable_client_scope.find(params[:client_id].to_i)
  end

  def title_for_show
    "#{@client.name} - Audit"
  end
end
