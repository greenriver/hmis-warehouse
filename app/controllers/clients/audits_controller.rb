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
    @restriction_users = User.with_deleted.where(id: @restriction_versions.map(&:clean_user_id).compact.map(&:to_i)).index_by(&:id)

    @audit_log = ActivityLog.where(item_model: 'GrdaWarehouse::Hud::Client', client_id: @client.id).
      includes(:user).
      order(created_at: :desc)
    @pagy, @audit_log = pagy(@audit_log, items: 25)
    @client_restricted = current_user.policy_context.client_restricted?(@client.id)
  end

  protected

  def set_client
    @client = destination_searchable_client_scope.find(params[:client_id].to_i)
  end

  def title_for_show
    "#{@client.pii_provider(user: current_user).full_name} - Audit"
  end
end
