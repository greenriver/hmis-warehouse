###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Clients
  class RestrictionsController < ApplicationController
    include AjaxModalRails::Controller
    include ClientPathGenerator
    include ClientDependentControllers

    before_action :set_client
    before_action :require_can_mark_restricted!
    after_action :log_client

    def show
      @restriction = DestinationClientRestriction.new(@client)
    end

    def update
      restriction = DestinationClientRestriction.new(@client)
      if params[:restricted] == '1'
        restriction.restrict!(user: current_user)
        flash[:notice] = 'Client restricted.'
      else
        restriction.unrestrict!
        flash[:notice] = if restriction.restricted_in_hmis?
          'Warehouse restriction removed. This client is still restricted in HMIS and can only be unrestricted there.'
        else
          'Client restriction removed.'
        end
      end
      redirect_to polymorphic_path(client_path_generator, id: @client.id)
    end

    private def set_client
      @client = client_source.destination.find(params[:client_id].to_i)
    end

    private def require_can_mark_restricted!
      not_authorized! unless current_user.policy_for(@client).can_mark_restricted?
    end
  end
end
