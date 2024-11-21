###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class TalentlmsController < ApplicationController
    before_action :require_can_manage_config!
    before_action :set_config, only: [:update, :edit, :destroy]
    before_action :set_site_config, only: [:index, :update_site_config]

    def index
      @configs = config_scope.order(:subdomain, :id)
    end

    def update_site_config
      @site_configs.update(site_config_params)
    end

    def new
      @config = config_scope.new
    end

    def create
      @config = config_scope.create(config_params)
      respond_with(@config, location: admin_talentlms_path)
    end

    def edit
    end

    def update
      @config.update(config_params)
      respond_with(@config, location: admin_talentlms_path)
    end

    def destroy
      @config.destroy
      respond_with(@config, location: admin_talentlms_path)
    end

    private def config_scope
      Talentlms::Config
    end

    private def set_config
      @config = config_scope.find(params[:id].to_i)
    end

    private def set_site_config
      @site_configs = site_config_scope.where(id: 1).first_or_create
    end

    def site_config_scope
      GrdaWarehouse::Config
    end

    def site_config_params
      params.require(:grda_warehouse_config).permit(
        :number_lms_courses_required,
      )
    end

    def config_params
      params.require(:talentlms_config).permit(
        :subdomain,
        :api_key,
        :create_new_accounts,
      )
    end
  end
end
