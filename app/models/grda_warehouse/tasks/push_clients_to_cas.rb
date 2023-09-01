###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Tasks
  class PushClientsToCas
    include NotifierConfig

    def initialize
      setup_notifier('Warehouse-CAS Sync')
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
        @notifier.ping(msg)
        return
      end
      @start_time = Time.current
      GrdaWarehouse::DataSource.with_advisory_lock(advisory_lock_key) do
        @client_ids = client_source.pluck(:id)
        updated_clients = []
        update_columns = (CasAccess::ProjectClient.column_names - ['id']).map(&:to_sym)
        CasAccess::ProjectClient.transaction do
          CasAccess::ProjectClient.update_all(sync_with_cas: false)
          @client_ids.each_slice(150) do |client_id_batch|
            to_update = []
            project_clients = CasAccess::ProjectClient.
              where(data_source_id: data_source.id, id_in_data_source: client_id_batch).
              index_by(&:id_in_data_source)
            ongoing_enrolled_project_details = GrdaWarehouse::Hud::Client.ongoing_enrolled_project_details(client_id_batch)
            preloads = [
              :vispdats,
              :processed_service_history,
              :hmis_client,
              :source_disabilities,
              :source_health_and_dvs,
              :source_exits,
              :client_files,
              source_clients: [
                :most_recent_current_living_situation,
                {
                  most_recent_pathways_or_rrh_assessment: [
                    :assessment_questions,
                    :user,
                  ],
                },
              ],
              cohort_clients: :cohort,
              source_enrollments: [:income_benefits, :exit, :ch_enrollment],
            ]
            if RailsDrivers.loaded.include?(:eccovia_data) && EccoviaData::Fetch.exists?
              preloads += [
                :source_eccovia_assessments,
                :source_eccovia_client_contacts,
                :source_eccovia_case_managers,
              ]
            end
            client_source.preload(preloads).
              where(id: client_id_batch).find_each do |client|
              project_client = project_clients[client.id] || CasAccess::ProjectClient.new(data_source_id: data_source.id, id_in_data_source: client.id)
              project_client.assign_attributes(attributes_for_cas_project_client(client))

              case GrdaWarehouse::Config.get(:cas_days_homeless_source)
              when 'days_homeless_plus_overrides'
                project_client.days_homeless = client.processed_service_history&.days_homeless_plus_overrides || client.days_homeless
              else
                project_client.days_homeless = client.days_homeless
              end

              project_client.calculated_last_homeless_night = client.date_of_last_homeless_service
              project_client.enrolled_project_ids = ongoing_enrolled_project_details[client.id]&.map(&:project_id)&.uniq
              enrollments = ongoing_enrolled_project_details[client.id]
              project_client.enrolled_in_th = client.enrolled_in_th(enrollments)
              project_client.enrolled_in_sh = client.enrolled_in_sh(enrollments)
              project_client.enrolled_in_so = client.enrolled_in_so(enrollments)
              project_client.enrolled_in_es = client.enrolled_in_es(enrollments)
              project_client.enrolled_in_rrh = client.enrolled_in_rrh(enrollments)
              project_client.enrolled_in_psh = client.enrolled_in_psh(enrollments)
              project_client.enrolled_in_ph = client.enrolled_in_ph(enrollments)
              project_client.date_days_homeless_verified = Date.current

              # Order the files by effective date to get the newest date for each tag, blank at the end
              project_client.file_tags = client.client_files.sort_by { |file| file.effective_date || 10.years.ago.to_date }.
                map { |f| f.tag_list.map { |tag| [tag, f.effective_date] } }.
                flatten(1).to_h

              project_client.needs_update = true
              to_update << project_client
            end
            to_insert = to_update.select { |c| c.id.blank? }
            to_upsert = to_update.select { |c| c.id.present? }

            CasAccess::ProjectClient.import!(to_upsert, on_duplicate_key_update: update_columns) if to_upsert.present?
            CasAccess::ProjectClient.import!(update_columns, to_insert) if to_insert.present?

            updated_clients += to_update
          end
        end
        maintain_cas_availability_table(@client_ids)

        unless updated_clients.empty?
          elapsed = Time.current - @start_time
          msg = "Updated #{updated_clients.size} ProjectClients in CAS and marked them available"
          Rails.logger.tagged({ task_name: 'Warehouse-CAS Sync', repeating_task: true, task_runtime: elapsed }) do
            @notifier.ping(msg)
          end
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
      @data_source ||= CasAccess::DataSource.where(name: 'DND Warehouse').first_or_create
    end

    def client_source
      GrdaWarehouse::Hud::Client.cas_active
    end

    # TODO: Need to update this to handle new contact format from Clarity, need to add which type of assessment is being sent.
    private def project_client_columns
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
        am_ind_ak_native: :cas_race_am_ind_ak_native,
        asian: :cas_race_asian,
        black_af_american: :cas_race_black_af_american,
        native_hi_pacific: :cas_race_native_hi_pacific,
        white: :cas_race_white,
        female: :cas_gender_female,
        male: :cas_gender_male,
        no_single_gender: :cas_gender_no_single_gender,
        transgender: :cas_gender_transgender,
        questioning: :cas_gender_questioning,
        ethnicity: :Ethnicity,
        disabling_condition: :disabling_condition?,
        hivaids_status: :hiv_response?,
        chronic_health_condition: :chronic_response?,
        mental_health_problem: :mental_response?,
        developmental_disability: :developmental_response?,
        physical_disability: :physical_response?,
        calculated_chronic_homelessness: :chronically_homeless_for_cas,
        calculated_first_homeless_night: :date_of_first_service,
        domestic_violence: :domestic_violence,
        disability_verified_on: :disability_verified_on,
        sync_with_cas: :active_in_cas?,
        force_remove_unavailable_fors: :force_remove_unavailable_fors,
        dmh_eligible: :dmh_eligible,
        va_eligible: :va_eligible,
        hues_eligible: :hues_eligible,
        hiv_positive: :hiv_positive,
        housing_release_status: :release_status_for_cas,
        housing_assistance_network_released_on: :consent_form_signed_on,
        us_citizen: :us_citizen,
        asylee: :asylee,
        ineligible_immigrant: :ineligible_immigrant,
        lifetime_sex_offender: :lifetime_sex_offender,
        meth_production_conviction: :meth_production_conviction,
        family_member: :family_member,
        child_in_household: :child_in_household,
        days_homeless_in_last_three_years: :days_homeless_in_last_three_years_cached,
        days_literally_homeless_in_last_three_years: :literally_homeless_last_three_years_cached,
        hmis_days_homeless_last_three_years: :hmis_days_homeless_in_last_three_years,
        hmis_days_homeless_all_time: :hmis_days_homeless_all_time,
        vispdat_score: :most_recent_vispdat_score,
        vispdat_length_homeless_in_days: :days_homeless_for_vispdat_prioritization,
        vispdat_priority_score: :calculate_vispdat_priority_score,
        ha_eligible: :ha_eligible,
        cspech_eligible: :cspech_eligible,
        income_total_monthly: :max_current_total_monthly_income,
        alternate_names: :alternate_names,
        congregate_housing: :congregate_housing,
        sober_housing: :sober_housing,
        active_cohort_ids: :cohort_ids_for_cas,
        assessment_score: :assessment_score_for_cas,
        ssvf_eligible: :ssvf_eligible,
        rrh_desired: :rrh_desired,
        youth_rrh_desired: :youth_rrh_desired,
        rrh_assessment_contact_info: :contact_info_for_rrh_assessment,
        rrh_assessment_collected_at: :cas_assessment_collected_at,
        entry_date: :cas_assessment_collected_at,
        requires_wheelchair_accessibility: :requires_wheelchair_accessibility,
        required_number_of_bedrooms: :required_number_of_bedrooms,
        required_minimum_occupancy: :required_minimum_occupancy,
        requires_elevator_access: :requires_elevator_access,
        neighborhood_interests: :neighborhood_ids_for_cas,
        interested_in_set_asides: :interested_in_set_asides,
        default_shelter_agency_contacts: :default_shelter_agency_contacts,
        tags: :cas_tags,
        vash_eligible: :vash_eligible,
        pregnancy_status: :cas_pregnancy_status,
        income_maximization_assistance_requested: :income_maximization_assistance_requested,
        pending_subsidized_housing_placement: :pending_subsidized_housing_placement,
        rrh_th_desired: :rrh_th_desired,
        sro_ok: :sro_ok,
        evicted: :evicted,
        dv_rrh_desired: :dv_rrh_desired,
        health_prioritized: :health_prioritized_for_cas?,
        assessment_name: :cas_assessment_name,
        majority_sheltered: :majority_sheltered,
        tie_breaker_date: :tie_breaker_date,
        financial_assistance_end_date: :financial_assistance_end_date,
        strengths: :strengths,
        challenges: :challenges,
        foster_care: :foster_care,
        open_case: :open_case,
        housing_for_formerly_homeless: :housing_for_formerly_homeless,
        need_daily_assistance: :need_daily_assistance,
        full_time_employed: :full_time_employed,
        can_work_full_time: :can_work_full_time,
        willing_to_work_full_time: :willing_to_work_full_time,
        rrh_successful_exit: :rrh_successful_exit,
        th_desired: :th_desired,
        drug_test: :drug_test,
        employed_three_months: :employed_three_months,
        willing_case_management: :willing_case_management,
        living_wage: :living_wage,
        heavy_drug_use: :heavy_drug_use,
        sober: :sober,
        site_case_management_required: :site_case_management_required,
        ongoing_case_management_required: :ongoing_case_management_required,
        currently_fleeing: :currently_fleeing,
        dv_date: :dv_date,
        assessor_first_name: :assessor_first_name,
        assessor_last_name: :assessor_last_name,
        assessor_email: :assessor_email,
        assessor_phone: :assessor_phone,
        match_group: :match_group,
        encampment_decomissioned: :encampment_decomissioned,
      }
    end

    private def attributes_for_cas_project_client(client)
      {}.tap do |options|
        project_client_columns.map do |destination, source|
          # puts "Processing: #{destination} from: #{source}"
          options[destination] = calculator_instance.value_for_cas_project_client(client: client, column: source)
        end
      end
    end

    # Only used to display attributes for a single client,
    # NOT used during sync to CAS
    def attributes_for_display(user, client)
      # Since we only care about one client at a time for this, we can
      # speed up queries by telling the calculator which client we are looking at
      calculator_instance.client_id = client.id
      attributes_for_cas_project_client(client).map do |k, value|
        next if skip_for_display(user).include?(k)

        [
          title_display_for(k),
          value_display_for(k, value),
          description_display_for(k),
        ]
      end.compact.sort_by(&:first)
    end

    def title_display_for(column)
      override = title_override(column)
      return override if override.present?

      column.to_s.humanize
    end

    def description_display_for(column)
      calculator_instance.description_for_column(column)
    end

    def value_display_for(key, value)
      if value.in?([true, false])
        ApplicationController.helpers.yes_no(value)
      elsif key == :ethnicity
        HudUtility.ethnicity(value)
      elsif key.in?([:veteran_status])
        HudUtility.no_yes_reasons_for_missing_data(value)
      elsif key == :neighborhood_interests
        value.map do |id|
          CasAccess::Neighborhood.find_by(id: id)&.name
        end&.to_sentence
      elsif key == :tags
        value.keys.map do |id|
          CasAccess::Tag.find(id).name
        end&.join('; ')
      elsif key == :default_shelter_agency_contacts
        value.join('; ')
      elsif key == :active_cohort_ids
        value.map do |id|
          GrdaWarehouse::Cohort.find(id).name
        end&.to_sentence
      elsif key.in?([:strengths, :challenges])
        value&.join(', ')&.titleize
      elsif value.is_a?(Array)
        value.join(', ')
      elsif key == :assessment_name
        value&.titleize
      else
        value
      end
    end

    private def title_override(column)
      @title_override = GrdaWarehouse::Hud::Client.cas_columns
      @title_override.deep_merge!(
        {
          homephone: 'Phone, home ',
          cellphone: 'Phone, cell',
          workphone: 'Phone, work',
          hivaids_status: 'HIV/AIDS status',
          consent_form_signed_on: _('Housing Release Signature Date'),
          ssvf_eligible: 'SSVF Eligible',
          rrh_desired: 'RRH Desired',
          youth_rrh_desired: 'Youth RRH Desired',
          rrh_assessment_contact_info: 'Assessment contact',
          rrh_assessment_collected_at: 'Assessment collection date',
          sro_ok: 'SRO OK',
          dv_rrh_desired: 'DV RRH Desired',
          rrh_th_desired: 'RRH TH Desired',
          active_cohort_ids: 'Active Cohorts',
          dv_date: 'Most recent date of DV',
          th_desired: 'TH Desired',
          vispdat_score: 'VI-SPDAT Score',
          vispdat_priority_score: 'VI-SPDAT Priority Score',
          vispdat_length_homeless_in_days: 'VI-SPDAT length homeless in days',
          rrh_successful_exit: 'RRH successful exit:',
          hmis_days_homeless_last_three_years: _('Days homeless in the last three years, from HMIS'),
          hmis_days_homeless_all_time: _('Total days homeless, from HMIS'),
          am_ind_ak_native: "Race: #{::HudUtility.race('AmIndAKNative')}",
          asian: "Race: #{::HudUtility.race('Asian')}",
          black_af_american: "Race: #{::HudUtility.race('BlackAfAmerican')}",
          native_hi_pacific: "Race: #{::HudUtility.race('NativeHIPacific')}",
          white: "Race: #{::HudUtility.race('White')}",
          female: "Gender: #{::HudUtility.gender(0)}",
          male: "Gender: #{::HudUtility.gender(1)}",
          no_single_gender: "Gender: #{::HudUtility.gender(4)}",
          transgender: "Gender: #{::HudUtility.gender(5)}",
          questioning: "Gender: #{::HudUtility.gender(6)}",
        },
      )
      @title_override[column]
    end

    private def skip_for_display(user)
      @skip_for_display ||= Set.new.tap do |keys|
        [
          :client_identifier,
          :first_name,
          :last_name,
          :middle_name,
          :ssn,
          :ssn_quality_code,
          :date_of_birth,
          :dob_quality_code,
          :alternate_names,
          :encampment_decomissioned,
        ].each do |k|
          keys << k
        end
        keys << :hiv_positive unless user.can_view_hiv_status?
        keys << :hues_eligible unless user.can_view_hiv_status?
        keys << :hivaids_status unless user.can_view_hiv_status?
        keys << :dmh_eligible unless user.can_view_dmh_status?
        keys << :vispdat_score unless user.can_view_vspdat?
        keys << :vispdat_length_homeless_in_days unless user.can_view_vspdat?
        keys << :vispdat_priority_score unless user.can_view_vspdat?
      end
    end

    private def calculator_instance
      @calculator_instance ||= GrdaWarehouse::Config.get(:cas_calculator).constantize.new
    end
  end
end
