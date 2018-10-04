module GrdaWarehouse::Tasks
  class PushClientsToCas
    require 'ruby-progressbar'
    include NotifierConfig
    attr_accessor :logger, :send_notifications, :notifier_config
    def initialize()
      setup_notifier('Warehouse-CAS Sync')
      self.logger = Rails.logger
    end

    # Update the ProjectClient table in the CAS with clients flagged with sync_with_cas
    def sync!
      # Fail gracefully if there's no CAS database setup
      return unless CasBase.db_exists?
      @client_ids = client_source.pluck(:id)
      updated_clients = Cas::ProjectClient.transaction do
        Cas::ProjectClient.update_all(sync_with_cas: false)
        client_source.where(id: @client_ids).each do |client|
          project_client = Cas::ProjectClient.
            where(data_source_id: data_source.id, id_in_data_source: client.id).
            first_or_initialize
          project_client_columns.map do |destination, source|
            project_client[destination] = client.send(source)
          end
          project_client.needs_update = true
          project_client.save!
        end
      end
      if updated_clients.size > 0
        msg = "Updated #{updated_clients.size} ProjectClients in CAS and marked them available"
        @notifier.ping msg if @send_notifications
      end
    end


    def data_source
      @data_source ||= Cas::DataSource.where(name: 'DND Warehouse').first_or_create
    end

    def client_source
      GrdaWarehouse::Hud::Client.cas_active
    end

    def project_client_columns
      {
        first_name: :FirstName,
        last_name: :LastName,
        middle_name: :MiddleName,
        ssn: :SSN,
        ssn_quality_code: :SSNDataQuality,
        date_of_birth: :DOB,
        dob_quality_code: :DOBDataQuality,
        veteran_status: :VeteranStatus,
        homephone: :home_phone,
        cellphone: :cell_phone,
        workphone: :work_phone,
        email: :email,
        substance_abuse_problem: :cas_substance_response,
        primary_race: :cas_primary_race_code,
        gender: :Gender,
        ethnicity: :Ethnicity,
        disabling_condition: :disabling_condition?,
        hivaids_status: :hiv_response?,
        chronic_health_condition: :chronic_response?,
        mental_health_problem: :mental_response?,
        developmental_disability: :developmental_response?,
        physical_disability: :physical_response?,
        # calculated_chronic_homelessness: :chronic?, # using sync_with_cas as a manual proxy
        calculated_chronic_homelessness: :chronically_homeless_for_cas,
        calculated_first_homeless_night: :date_of_first_service,
        calculated_last_homeless_night: :date_of_last_homeless_service,
        domestic_violence: :domestic_violence?,
        disability_verified_on: :disability_verified_on,
        housing_assistance_network_released_on: :consent_form_signed_on,
        sync_with_cas: :active_in_cas?,
        dmh_eligible: :dmh_eligible,
        va_eligible: :va_eligible,
        hues_eligible: :hues_eligible,
        hiv_positive: :hiv_positive,
        housing_release_status: :release_status_for_cas,
        us_citizen: :us_citizen,
        asylee: :asylee,
        ineligible_immigrant: :ineligible_immigrant,
        lifetime_sex_offender: :lifetime_sex_offender,
        meth_production_conviction: :meth_production_conviction,
        family_member: :family_member,
        child_in_household: :child_in_household,
        days_homeless: :days_homeless,
        days_homeless_in_last_three_years: :days_homeless_in_last_three_years,
        days_literally_homeless_in_last_three_years: :literally_homeless_last_three_years,
        vispdat_score: :most_recent_vispdat_score,
        vispdat_length_homeless_in_days: :days_homeless_for_vispdat_prioritization,
        vispdat_priority_score: :calculate_vispdat_priority_score,
        ha_eligible: :ha_eligible,
        cspech_eligible: :cspech_eligible,
        income_total_monthly: :max_current_total_monthly_income,
        alternate_names: :alternate_names,
        congregate_housing: :congregate_housing,
        sober_housing: :sober_housing,
        enrolled_project_ids: :ongoing_enrolled_project_ids,
        active_cohort_ids: :active_cohort_ids,
        assessment_score: :score_for_rrh_assessment,
        ssvf_eligible: :ssvf_eligible,
        rrh_desired: :rrh_desired,
        youth_rrh_desired: :youth_rrh_desired,
        rrh_assessment_contact_info: :contact_info_for_rrh_assessment,
        rrh_assessment_collected_at: :rrh_assessment_collected_at,
        enrolled_in_th: :enrolled_in_th,
        enrolled_in_sh: :enrolled_in_sh,
        enrolled_in_so: :enrolled_in_so,
        enrolled_in_es: :enrolled_in_es,
        requires_wheelchair_accessibility: :requires_wheelchair_accessibility,
        required_number_of_bedrooms: :required_number_of_bedrooms,
        required_minimum_occupancy: :required_minimum_occupancy,
        requires_elevator_access: :requires_elevator_access,
      }
    end
  end
end
