###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Clients::AuditsController < ApplicationController
  include ClientPathGenerator
  include ClientDependentControllers
  before_action :require_can_audit_clients!
  before_action :set_client
  after_action :log_client

  def index
    @restriction_versions = DestinationClientRestriction.new(@client).versions.to_a
    @restriction_users = User.where(id: @restriction_versions.map(&:clean_user_id).compact.map(&:to_i)).index_by(&:id)

    client_id = @client.id
    al_t = ActivityLog.arel_table
    @audit_log = ActivityLog.where(item_model: 'GrdaWarehouse::Hud::Client').
      where(al_t[:path].matches("%clients/#{client_id}/%"). # contains client_id
            or(al_t[:path].matches("%clients/#{client_id}"))). # ends with client_id
      order(created_at: :desc)
    @pagy, @audit_log = pagy(@audit_log, items: 50)
  end

  protected

  # Titles are stored at visit time as "<name>" or "<name> - <page>", so rows logged before
  # a restriction still carry the client's name.
  helper_method def audit_item_title(item)
    return item.title || item.controller_name unless item.title && current_user.policy_context.client_restricted?(@client.id)

    redacted_name = @client.pii_provider(user: current_user).full_name
    return redacted_name unless item.title.include?(' - ')

    "#{redacted_name} - #{item.title.rpartition(' - ').last}"
  end

  def set_client
    @client = destination_searchable_client_scope.find(params[:client_id].to_i)
  end

  def title_for_show
    "#{@client.pii_provider(user: current_user).full_name} - Audit"
  end
end
