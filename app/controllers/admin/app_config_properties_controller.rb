###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  class AppConfigPropertiesController < ApplicationController
    before_action :require_can_manage_config!
    before_action :set_property, only: [:edit, :update, :destroy]

    def index
      @properties = AppConfigProperty.all.order(:key)
      @pagy, @properties = pagy(@properties)
    end

    def new
      @property = AppConfigProperty.new
    end

    def create
      @property = AppConfigProperty.new(property_params)

      if @property.save
        redirect_to admin_app_config_properties_path, notice: 'App config property created.'
      else
        render :new
      end
    end

    def edit
    end

    def update
      if @property.update(property_params)
        redirect_to admin_app_config_properties_path, notice: 'App config property updated.'
      else
        render :edit
      end
    end

    def destroy
      @property.destroy
      redirect_to admin_app_config_properties_path, notice: 'App config property deleted.'
    end

    private

    def set_property
      @property = AppConfigProperty.find(params[:id])
    end

    def property_params
      params.require(:app_config_property).permit(:key, :value)
    end
  end
end
