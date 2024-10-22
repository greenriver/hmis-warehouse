###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class TalentlmsController < ApplicationController
    before_action :require_can_manage_config!
    before_action :set_config, only: [:update, :edit, :destroy]

    def index
      @configs = config_scope.order(:subdomain, :id)
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
      @config.courses.each(&:destroy)
      @config.destroy
      respond_with(@config, location: admin_talentlms_path)
    end

    private def config_scope
      Talentlms::Config
    end

    private def set_config
      @config = config_scope.find(params[:id].to_i)
    end

    def config_params
      params.require(:talentlms_config).permit(
        :subdomain,
        :api_key,
      )
    end
  end
end
