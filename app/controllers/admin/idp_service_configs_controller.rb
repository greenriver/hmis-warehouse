###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  class IdpServiceConfigsController < ApplicationControllerV2
    authorize_with { current_user.can_manage_config? }
    before_action :set_idp_service_config, only: [:edit, :update, :destroy, :test]

    def index
      @idp_service_configs = idp_service_config_scope.order(:name, :id)
    end

    def new
      @idp_service_config = ::Idp::ServiceConfig.new
    end

    def create
      @idp_service_config = ::Idp::ServiceConfig.new(idp_service_config_params)
      @idp_service_config.save
      respond_with(@idp_service_config, location: admin_idp_service_configs_path)
    end

    def edit
    end

    def update
      @idp_service_config.update(idp_service_config_params)
      respond_with(@idp_service_config, location: admin_idp_service_configs_path)
    end

    def destroy
      @idp_service_config.destroy
      respond_with(@idp_service_config, location: admin_idp_service_configs_path)
    end

    def test
      service = @idp_service_config.to_service
      result = service.test_connection

      if result[:success]
        flash[:success] = result[:message] || 'Connection successful'
      else
        flash[:error] = result[:message] || 'Connection failed'
      end

      redirect_to admin_idp_service_configs_path
    rescue ::Idp::ServiceError => e
      # A misconfigured record (e.g. missing client_id) raises while building the
      # service; surface it as a flash rather than a 500.
      flash[:error] = "Connection failed: #{e.message}"
      redirect_to admin_idp_service_configs_path
    end

    private

    def set_idp_service_config
      @idp_service_config = idp_service_config_scope.find(params[:id])
    end

    def idp_service_config_params
      params.require(:idp_service_config).permit(
        :provider,
        :connector_id,
        :name,
        :api_url,
        :service_token,
        :client_id,
        :keycloak_realm,
        :okta_org_id,
        :active,
      )
    end

    def idp_service_config_scope
      ::Idp::ServiceConfig.all
    end

    def flash_interpolation_options
      { resource_name: 'IDP service config' }
    end
  end
end
