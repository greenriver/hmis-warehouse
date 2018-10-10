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
        :release_duration,
        :cas_available_method,
        :cas_flag_method,
        :site_coc_codes,
        :default_coc_zipcodes,
        :family_calculation_method,
        :continuum_name,
        :cas_url,
        :url_of_blank_consent_form,
        :allow_partial_release,
        :window_access_requires_release,
        :show_partial_ssn_in_window_search_results,
        :so_day_as_month,
        :ahar_psh_includes_rrh,
        :allow_multiple_file_tags,
        :infer_family_from_household_id,
        client_details: []
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
