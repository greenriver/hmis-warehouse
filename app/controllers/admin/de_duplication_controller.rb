###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class DeDuplicationController < ApplicationController
    before_action :require_can_manage_auto_client_de_duplication!
    before_action :set_config

    def index
    end

    def update
      accept = config_params.dig(:auto_de_duplication_accept_threshold)
      reject = config_params.dig(:auto_de_duplication_reject_threshold)
      if accept && reject.present? && reject >= accept
        flash[:error] = 'Accept threshold must be higher than the reject threshold'
        redirect_to action: :index
        return
      end

      @config.assign_attributes(config_params)
      config_source.invalidate_cache
      if @config.save
        redirect_to({ action: :index }, notice: 'Thresholds Set')
      else
        render action: :index, error: 'The configuration failed to save.'
      end
    end

    private def config_params
      params.require(:grda_warehouse_config).permit(
        :auto_de_duplication_accept_threshold,
        :auto_de_duplication_reject_threshold,
        :auto_de_duplication_enabled,
      )
    end

    def set_config
      @config = config_source.where(id: 1).first_or_create
    end

    def config_source
      GrdaWarehouse::Config
    end
  end
end
