###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
        redirect_to({ action: :index }, notice: 'Configuration updated')
      else
        render action: :index, error: 'The configuration failed to save.'
      end
    end

    private def config_params
      params.require(:grda_warehouse_config).permit(
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
        :chronic_definition,
        :vispdat_prioritization_scheme,
        :rrh_cas_readiness,
        :show_vispdats_on_dashboards,
        :cas_days_homeless_source,
        :consent_visible_to_all,
        :verified_homeless_history_visible_to_all,
        :only_most_recent_import,
        :expose_coc_code,
        :auto_confirm_consent,
        :health_emergency,
        :health_emergency_tracing,
        :health_priority_age,
        :health_claims_data_path,
        :multi_coc_installation,
        :auto_de_duplication_accept_threshold,
        :auto_de_duplication_reject_threshold,
        :pii_encryption_type,
        :auto_de_duplication_enabled,
        :request_account_available,
        :dashboard_lookback,
        :domestic_violence_lookback_days,
        :support_contact_email,
        :completeness_goal,
        :excess_goal,
        :timeliness_goal,
        :income_increase_goal,
        :ph_destination_increase_goal,
        :move_in_date_threshold,
        :pf_universal_data_element_threshold,
        :pf_utilization_min,
        :pf_utilization_max,
        :pf_timeliness_threshold,
        :pf_show_income,
        :pf_show_additional_timeliness,
        :cas_sync_months,
        :send_sms_for_covid_reminders,
        :bypass_2fa_duration,
        :enable_system_cohorts,
        :currently_homeless_cohort,
        :enable_youth_hrp,
        :show_client_last_seen_info_in_client_details,
        :ineligible_uses_extrapolated_days,
        :warehouse_client_name_order,
        :cas_calculator,
        :service_register_visible,
        client_details: [],
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
