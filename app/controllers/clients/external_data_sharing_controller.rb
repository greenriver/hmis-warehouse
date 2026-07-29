###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Clients
  class ExternalDataSharingController < ApplicationController
    include ClientPathGenerator
    include ClientDependentControllers

    before_action :require_can_edit_clients!
    before_action :set_client
    after_action :log_client

    def show
      redirect_to(polymorphic_path(client_path_generator, id: @client.id)) unless ClientExternalDataSharing.enabled?
    end

    def update
      redirect_to(polymorphic_path(client_path_generator, id: @client.id)) and return unless ClientExternalDataSharing.enabled?

      ClientExternalDataSharing.new(@client).set_exclusion!(
        value: params[:exclude_from_external_data_sharing] == '1',
        user: current_user,
      )
      flash[:notice] = 'External data sharing preference saved.'
      redirect_to polymorphic_path(client_path_generator, id: @client.id)
    end

    protected

    def set_client
      @client = client_source.destination.find(params[:client_id].to_i)
    end
  end
end
