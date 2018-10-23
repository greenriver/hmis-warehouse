class Clients::AuditsController < ApplicationController
  include ClientPathGenerator

  def index
    client_id = params[:client_id].to_i
    @client = client_scope.find(client_id)
    al_t = ActivityLog.arel_table
    @audit_log = ActivityLog.where(item_model: GrdaWarehouse::Hud::Client.name).
        where(al_t[:path].matches("%clients/#{client_id}/%").  # contains client_id
            or(al_t[:path].matches("%clients/#{client_id}"))). # ends with client_id
        order(created_at: :desc)
  end

  def client_scope
    GrdaWarehouse::Hud::Client.destination
  end
end
