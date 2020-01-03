###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Clients
  class EtoApiController < ApplicationController
    include ClientPathGenerator
    include ClientDependentControllers

    before_action :require_can_view_client_window!
    before_action :set_client
    after_action :log_client

    def show
      render json: @client.api_status
    end

    def update
      session[:return_to] ||= request.referer
      @client.update_via_api
      redirect_to session.delete(:return_to)
    end

    def set_client
      @client = searchable_client_scope.find(params[:client_id].to_i)
    end
  end
end
