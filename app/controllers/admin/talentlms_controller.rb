###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class TalentlmsController < ApplicationController
    before_action :require_can_manage_config!
    before_action :set_config, only: [:index, :edit, :update]

    def index
    end

    def new
      @config = config_scope.first_or_initialize
      # If a record already exists, we want to be editing. This redirect will
      # send the user to edit the existing record if one is found.
      # If we ever have the need for multiple records at once, this will need to be adjusted.
      redirect_to edit_admin_talentlm_path(@config) unless @config.new_record?
    end

    def create
      @config = config_scope.new
      if @config.update(config_params)
        respond_with(@config, location: edit_admin_talentlm_path(@config))
      else
        render 'new'
      end
    end

    def edit
    end

    def update
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

    private def set_config
      @config = config_scope.first_or_initialize

      # Checks to make sure we are working with the expected record in the database.
      # If a record already exists, we want to be editing that record. If one does
      # not exist, we want to be creating it.
      # If we ever have the need for multiple records at once, this will need to be adjusted.
      redirect_to new_admin_talentlm_path if @config.new_record?
      redirect_to edit_admin_talentlm_path(@config) if @config.id && @config.id != params[:id].to_i
    end
  end
end
