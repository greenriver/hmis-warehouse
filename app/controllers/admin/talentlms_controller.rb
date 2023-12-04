###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class TalentlmsController < ApplicationController
    before_action :require_can_manage_config!

    def index
      @config = config_scope.first_or_initialize
      redirect_to new_admin_talentlm_path if @config.new_record?
      redirect_to edit_admin_talentlm_path(@config) unless @config.new_record?
    end

    def new
      @config = config_scope.first_or_initialize
    end

    def create
      @config = config_scope.create(config_params)
      respond_with(@config, location: admin_talentlms_path(@config))
    end

    def edit
      @config = config_scope.first_or_initialize
    end

    def update
      @config = config_scope.first_or_initialize
      @config.update(config_params)
      respond_with(@config, location: edit_admin_talentlm_path(@config))
    end

    private def config_scope
      Talentlms::Config
    end

    def config_params
      params.require(:talentlms_config).permit(
        :subdomain,
        :api_key,
        :courseid,
      )
    end
  end
end
