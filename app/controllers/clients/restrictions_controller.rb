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
      case params[:restricted]
      when '1'
        restriction.restrict!(user: current_user)
        flash[:notice] = 'Client restricted.'
      when '0'
        removed = restriction.unrestrict!(user: current_user)
        flash[:notice] = unrestrict_message(removed: removed, in_hmis: restriction.restricted_in_hmis?)
      else
        return head :bad_request
      end
      redirect_to polymorphic_path(client_path_generator, id: @client.id)
    end

    private def unrestrict_message(removed:, in_hmis:)
      if removed
        in_hmis ? 'Warehouse restriction removed. This client is still restricted in HMIS and can only be unrestricted there.' : 'Client restriction removed.'
      else
        in_hmis ? 'This client is restricted in HMIS and can only be unrestricted there.' : 'Client was not restricted.'
      end
    end

    private def set_client
      @client = client_source.destination.find(params[:client_id].to_i)
    end

    private def require_can_mark_restricted!
      not_authorized! unless current_user.policy_for(@client).can_mark_restricted?
    end
  end
end
