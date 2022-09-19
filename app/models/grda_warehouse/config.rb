###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class Config < GrdaWarehouseBase
    serialize :client_details, Array
    validates :cas_sync_project_group_id, presence: { message: 'is required for the selected sync method.' }, if: ->(o) { o.cas_available_method.to_sym == :project_group }

    after_save :invalidate_cache

    def self.available_cas_methods
      {
        'Use Available in CAS flag' => :cas_flag,
        'Use potentially chronic report' => :chronic,
        'Use HUD chronic report' => :hud_chronic,
        'All clients with a release on file' => :release_present,
        'Active clients within range' => :active_clients,
        'Clients in project group' => :project_group,
      }
    end

    def self.available_cas_sync_months
      {
        'One Month' => 1,
        'Three Months' => 3,
        'Six Months' => 6,
        'Nine Months' => 9,
        'One Year' => 12,
      }
    end

    def self.available_cas_flag_methods
      {
        'A human should review qualifications' => :manual,
        'Trust the uploaded files' => :file,
      }
    end

    def self.available_verified_homeless_history_methods
      {
        'Include enrollments from data sources that are visible in the window.' => :visible_in_window,
        'Include enrollments that are visible to the user.' => :visible_to_user,
        'Include all enrollments if client has a release that grants the user access to the client. If no release, only include enrollments that are visible to the user.' => :release,
        'Include all enrollments' => :all_enrollments,
      }
    end

    def self.family_calculation_methods
      {
        'At least one adult & child' => :adult_child,
        'More than one person, regardless of age' => :multiple_people,
      }
    end

    def self.available_release_durations
      [
        'Indefinite',
        'One Year',
        'Two Years',
        'Use Expiration Date',
      ]
    end

    def self.available_chronic_definitions
      {
        'Potentially chronic' => :chronics,
        'HUD definition' => :hud_chronics,
      }
    end

    def self.available_vispdat_prioritization_schemes
      {
        'Length of time Homeless' => :length_of_time,
        'Veteran status (100)' => :veteran_status,
        'Vets (100), family (50), youth (25)' => :vets_family_youth,
      }
    end

    def self.available_days_homeless_sources
      {
        'Calculated days homeless' => :days_homeless,
        'Calculated days homeless + verified additional days' => :days_homeless_plus_overrides,
      }
    end

    def self.available_health_emergencies
      {
        'Boston COVID-19' => :boston_covid_19,
        'COVID-19 -- Vaccination Only' => :covid_19_vaccinations_only,
      }
    end

    def self.available_health_emergency_tracings
      {
        'COVID-19' => :covid_19,
      }
    end

    def self.available_encryption_types
      {
        'None' => :none,
        'PII Encrypted' => :pii,
      }
    end

    def self.dv_days
      {
        'Indefinite' => 0,
        'Three Years' => 1095,
        'One Year' => 365,
        'Six months' => 180,
        'Three months' => 90,
        'One month' => 30,
      }
    end

    def self.available_bypass_2fa_durations
      {
        'Disable Bypassing' => 0,
        '7 Days' => 7,
        '15 Days' => 15,
        '30 Days' => 30,
      }
    end

    def self.available_warehouse_client_name_orders
      {
        'Name is set initially and not changed' => :earliest,
        'Name is set to most recently changed source client' => :latest,
      }
    end

    def self.available_cas_calculators
      {
        'Boston Pathways' => 'GrdaWarehouse::CasProjectClientCalculator::Boston',
        'Tarrant HAT' => 'GrdaWarehouse::CasProjectClientCalculator::TcHat',
        'MDHA' => 'GrdaWarehouse::CasProjectClientCalculator::Mdha',
        'Default' => 'GrdaWarehouse::CasProjectClientCalculator::Default',
      }
    end

    def self.available_roi_models
      {
        'Explicit' => :explicit,
        'Implicit' => :implicit,
      }
    end

    def self.available_client_dashboards
      {
        'Default' => :default,
        'VA' => :va,
      }
    end

    def self.client_search_available?
      get(:pii_encryption_type).to_sym.in?([:none])
    end

    def self.currrent_health_emergency_tracing_title
      available_health_emergency_tracings.invert[get(:health_emergency_tracing).to_sym] || ''
    end

    def self.current_health_emergency_title
      available_health_emergencies.invert[get(:health_emergency)&.to_sym] || ''
    end

    def self.cas_sync_range
      current_range = get(:cas_sync_months) || 3
      (current_range.months.ago.to_date..Date.current)
    end

    def self.cas_sync_project_group
      project_group_id = get(:cas_sync_project_group_id)
      GrdaWarehouse::ProjectGroup.find(project_group_id)
    end

    def invalidate_cache
      self.class.invalidate_cache
    end

    def self.invalidate_cache
      @settings = nil
      @settings_update_at = nil
    end

    def self.get(config)
      # Use cached config for 30 seconds
      return @settings.public_send(config) if @settings && @settings_update_at.present? && @settings_update_at > 30.seconds.ago

      @settings = first_or_create
      @settings_update_at = Time.current
      @settings.public_send(config)
    end

    def self.default_site_coc_codes
      get(:site_coc_codes).presence&.split(/,\s*/)
    end

    def self.implicit_roi?
      get(:roi_model).to_s == 'implicit'
    end

    def self.known_configs
      [
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
        :veteran_cohort,
        :youth_cohort,
        :youth_no_child_cohort,
        :youth_and_child_cohort,
        :chronic_cohort,
        :adult_and_child_cohort,
        :adult_only_cohort,
        :youth_hoh_cohort,
        :youth_hoh_cohort_project_group_id,
        :enable_youth_hrp,
        :show_client_last_seen_info_in_client_details,
        :ineligible_uses_extrapolated_days,
        :warehouse_client_name_order,
        :cas_calculator,
        :service_register_visible,
        :enable_youth_unstably_housed,
        :cas_sync_project_group_id,
        :system_cohort_processing_date,
        :system_cohort_date_window,
        :roi_model,
        :client_dashboard,
        :require_service_for_reporting_default,
        :supplemental_enrollment_importer,
        :verified_homeless_history_method,
        :chronic_tab_justifications,
        :chronic_tab_roi,
        client_details: [],
      ]
    end

    def self.arbiter_class
      # FIXME: for now, just return the one known one
      ClientAccessControl::EnrollmentArbiter if RailsDrivers.loaded.include?(:client_access_control)
    end

    def self.active_supplemental_enrollment_importer_class
      supplemental_enrollment_importer_name = available_supplemental_enrollment_importers.values.detect do |class_name|
        get(:supplemental_enrollment_importer) == class_name
      end || default_supplemental_enrollment_importers.values.first
      supplemental_enrollment_importer_name.constantize
    end

    def self.available_supplemental_enrollment_importers
      Rails.application.config.supplemental_enrollment_importers[:available].presence || default_supplemental_enrollment_importers
    end

    def self.add_supplemental_enrollment_importer(name, class_name)
      importers = default_supplemental_enrollment_importers
      importers[name] = class_name
      Rails.application.config.supplemental_enrollment_importers[:available] = importers.sort.to_h
    end

    def self.default_supplemental_enrollment_importers
      {
        'Default' => 'GrdaWarehouse::Tasks::EnrollmentExtrasImport',
      }
    end
  end
end
