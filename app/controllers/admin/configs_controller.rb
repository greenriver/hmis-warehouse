module Admin
  class ConfigsController < ApplicationController
    before_action :require_can_manage_config!
    before_action :set_config

    def index
      
    end

    def update
      if @config.update(config_params)
        redirect_to({action: :index}, notice: 'Configuration updated')
      else
        render action: :index, error: 'The configuration failed to save.'
      end
    end

    private def config_params
      p = params.require(:grda_warehouse_config).permit(
        :last_name,
        :eto_api_available,
        :healthcare_available,
        :project_type_override,
        :cas_available_method,
        :site_coc_codes,
        :family_calculation_method,
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
