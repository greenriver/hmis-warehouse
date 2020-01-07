###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Tasks
  class PushClientsToCas
    require 'ruby-progressbar'
    include NotifierConfig
    attr_accessor :logger, :send_notifications, :notifier_config
    def initialize()
      setup_notifier('Warehouse-CAS Sync')
      self.logger = Rails.logger
    end

    private def advisory_lock_key
      'push-clients-to-cas'
    end

    # Update the ProjectClient table in the CAS with clients flagged with sync_with_cas
    def sync!
      # Fail gracefully if there's no CAS database setup
      return unless CasBase.db_exists?
      if GrdaWarehouse::DataSource.advisory_lock_exists?(advisory_lock_key)
        msg = 'Other CAS Sync in progress, exiting.'
        logger.warn msg
        @notifier.ping(msg) if @send_notifications
        return
      end
      GrdaWarehouse::DataSource.with_advisory_lock(advisory_lock_key) do
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

            case GrdaWarehouse::Config.get(:cas_days_homeless_source)
            when 'days_homeless_plus_overrides'
              project_client.days_homeless = client.processed_service_history&.days_homeless_plus_overrides || client.days_homeless
            else
              project_client.days_homeless = client.days_homeless
            end

            project_client.date_days_homeless_verified = Date.current
            project_client.needs_update = true
            project_client.save!
          end
        end
        maintain_cas_availability_table(@client_ids)

        if updated_clients.size > 0
          msg = "Updated #{updated_clients.size} ProjectClients in CAS and marked them available"
          @notifier.ping msg if @send_notifications
        end
      end
    end

    # if the client was available and isn't included in this set
    #   close the record
    # if the client isn't already available
    #   add a new record
    def maintain_cas_availability_table client_ids
      GrdaWarehouse::CasAvailability.already_available.where.not(client_id: client_ids).
        update_all(unavailable_at: Time.now)
      already_available = GrdaWarehouse::CasAvailability.already_available.pluck(:client_id)
      available_at = Time.now
      (client_ids - already_available).each do |id|
        client = GrdaWarehouse::Hud::Client.find id
        GrdaWarehouse::CasAvailability.create(
          client_id: id,
          available_at: available_at,
          part_of_a_family: client.family_member,
          age_at_available_at: client.age,
        )
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
        client_identifier: :id,
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
        # days_homeless: :days_homeless,
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
        active_cohort_ids: :cohort_ids_for_cas,
        assessment_score: :assessment_score_for_cas,
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
        neighborhood_interests: :neighborhood_ids_for_cas,
        interested_in_set_asides: :interested_in_set_asides,
        default_shelter_agency_contacts: :default_shelter_agency_contacts,
        tags: :cas_tags,
        vash_eligible: :vash_eligible,
        pregnancy_status: :cas_pregnancy_status
      }
    end
  end
end
