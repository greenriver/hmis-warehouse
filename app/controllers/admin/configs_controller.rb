###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  class ConfigsController < ApplicationController
    before_action :require_can_manage_config!
    before_action :set_config

    def index
    end

    def update
      @config.assign_attributes(config_params)
      config_source.invalidate_cache
      if @config.save
        # If ROI model changed, trigger housing release status updates
        if @config.saved_change_to_roi_model?
          Rails.logger.info "ROI model changed from #{@config.roi_model_previous_change.first} to #{@config.roi_model_previous_change.last}. Triggering housing release status updates."
          GrdaWarehouse::Tasks::UpdateHousingReleaseStatusesJob.perform_later
        end

        redirect_to({ action: :index }, notice: 'Configuration updated')
      else
        render action: :index, error: 'The configuration failed to save.'
      end
    end

    private def config_params
      params.require(:grda_warehouse_config).permit(config_source.known_configs)
    end

    def set_config
      @config = config_source.where(id: 1).first_or_create
    end

    def config_source
      GrdaWarehouse::Config
    end
  end
end
