module Admin
  class ConfigsController < ApplicationController
    before_action :require_can_manage_config!
    before_action :set_config

    def index
      
    end

    def update
      tag_list = config_params[:tag_list].select(&:present?)
      @config.assign_attributes(config_params)
      @config.document_ready_list = tag_list    
      config_source.invalidate_cache
      if @config.save
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
        :default_coc_zipcodes,
        :family_calculation_method,
        :continuum_name,
        tag_list: [],
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
