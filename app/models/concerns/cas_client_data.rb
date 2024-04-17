###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CasClientData
  extend ActiveSupport::Concern
  included do
    scope :dmh_eligible, -> do
      where.not(dmh_eligible: false)
    end

    scope :va_eligible, -> do
      where.not(va_eligible: false)
    end

    scope :hues_eligible, -> do
      where.not(hues_eligible: false)
    end

    scope :hiv_positive, -> do
      where.not(hiv_positive: false)
    end

    def cas_calculator_instance
      @cas_calculator_instance ||= GrdaWarehouse::Config.get(:cas_calculator).constantize.new
    end

    def self.cas_columns
      @cas_columns ||= cas_columns_data.transform_values { |v| v[:title] }
    end

    def self.cas_columns_data
      @cas_columns_data ||= {
        disability_verified_on: { title: Translation.translate('Disability Verification on File'), description: 'Date disability verification file was uploaded' },
        housing_release_status: { title: Translation.translate('Housing Release Status'), description: 'Release status is governed by uploaded files' },
        full_housing_release: { title: Translation.translate('Full HAN Release on File'), description: 'Does the client have a full release on file?' },
        limited_cas_release: { title: Translation.translate('Limited CAS Release on File'), description: 'Does the client have a partial release on file?' },
        sync_with_cas: { title: Translation.translate('Available for matching in CAS'), description: "Based on the chosen method for sending clients to CAS. Curently: #{GrdaWarehouse::Config.available_cas_methods.invert[GrdaWarehouse::Config.get(:cas_available_method).to_sym]}" },
        dmh_eligible: { title: Translation.translate('DMH Eligible'), description: 'Unused' },
        va_eligible: { title: Translation.translate('VA Eligible'), description: 'Unused' },
        hues_eligible: { title: Translation.translate('HUES Eligible'), description: 'Unused' },
        hiv_positive: { title: Translation.translate('HIV+'), description: 'Unused' },
        chronically_homeless_for_cas: { title: Translation.translate('Chronically Homeless for CAS'), description: 'Unused' },
        us_citizen: { title: Translation.translate('U.S Citizen or Permanent Resident'), description: 'Unused' },
        asylee: { title: Translation.translate('Asylee, Refugee'), description: 'Unused' },
        ineligible_immigrant: { title: Translation.translate('Ineligible Immigrant (Including Undocumented)'), description: 'Unused' },
        lifetime_sex_offender: { title: Translation.translate('Life-Time Sex Offender'), description: 'Unused' },
        meth_production_conviction: { title: Translation.translate('Meth Production Conviction'), description: 'Unused' },
        family_member: { title: Translation.translate('Part of a family'), description: 'Unused' },
        child_in_household: { title: Translation.translate('Children under age 18 in household'), description: 'Unused' },
        ha_eligible: { title: Translation.translate('Housing Authority Eligible'), description: 'Unused' },
        cspech_eligible: { title: Translation.translate('CSPECH Eligible'), description: 'Unused' },
        congregate_housing: { title: Translation.translate('Willing to live in congregate housing'), description: 'Unused' },
        sober_housing: { title: Translation.translate('Appropriate for sober supportive housing'), description: 'Unused' },
        requires_wheelchair_accessibility: { title: Translation.translate('Requires wheelchair accessible unit'), description: 'Unused' },
        required_number_of_bedrooms: { title: Translation.translate('Minimum number of bedrooms'), description: 'Unused' },
        required_minimum_occupancy: { title: Translation.translate('Minimum occupancy'), description: 'Unused' },
        requires_elevator_access: { title: Translation.translate('Requires ground floor unit or elevator access'), description: 'Unused' },
        cas_match_override: { title: Translation.translate('Override CAS Match Date'), description: 'Unused' },
        vash_eligible: { title: Translation.translate('VASH Eligible'), description: 'Unused' },
        health_prioritized: { title: Translation.translate('Health Priority'), description: 'Unused' },
        tie_breaker_date: { title: Translation.translate('Tie Breaker Date'), description: 'Unused' },
        financial_assistance_end_date: { title: Translation.translate('Financial Assistance End Date'), description: 'Unused' },
        strengths: { title: Translation.translate('Strengths'), description: 'Unused' },
        challenges: { title: Translation.translate('Challenges'), description: 'Unused' },
        foster_care: { title: Translation.translate('Foster care as youth'), description: 'Unused' },
        open_case: { title: Translation.translate('Current open case'), description: 'Unused' },
        housing_for_formerly_homeless: { title: Translation.translate('Prefers housing for formerly homeless'), description: 'Unused' },
        drug_test: { title: Translation.translate('Able to pass a drug test'), description: 'Unused' },
        heavy_drug_use: { title: Translation.translate('History of heavy drug use'), description: 'Unused' },
        sober: { title: Translation.translate('Clean/sober for at least one year'), description: 'Unused' },
        willing_case_management: { title: Translation.translate('Willing to engage with housing case management'), description: 'Unused' },
        employed_three_months: { title: Translation.translate('Employed for 3 or more months'), description: 'Unused' },
        living_wage: { title: Translation.translate('Earning a living wage ($13 or more)'), description: 'Unused' },
        match_group: { title: 'Match group', description: 'Unused' },
        can_work_full_time: { title: 'Can the client work full time?', description: 'Unused' },
        full_time_employed: { title: 'Is the client employed full time?', description: 'Unused' },
        force_remove_unavailable_fors: { title: 'Force the client to be active in CAS', description: 'Unused' },
        majority_sheltered: { title: 'Sheltered recently', description: 'Unused' },
      }
    end

    # NOTE: these should be kept in-sync with the attr_accessors at the bottom
    def self.ignored_for_batch_maintenance
      [
        :majority_sheltered,
        :tie_breaker_date,
        :financial_assistance_end_date,
        :strengths,
        :challenges,
        :foster_care,
        :open_case,
        :housing_for_formerly_homeless,
        :hivaids_status,
        :drug_test,
        :heavy_drug_use,
        :sober,
        :willing_case_management,
        :employed_three_months,
        :living_wage,
        :housing_release_status,
      ]
    end

    def self.manual_cas_columns
      cas_columns.except(:hiv_positive, :dmh_eligible, :chronically_homeless_for_cas, :full_housing_release, :limited_cas_release, :housing_release_status, :sync_with_cas, :hues_eligible, :disability_verified_on, :required_number_of_bedrooms, :required_minimum_occupancy, :cas_match_override, :health_prioritized, :tie_breaker_date, :vispdat_length_homeless_in_days).
        keys
    end

    def self.file_cas_columns
      cas_columns.except(:hiv_positive, :dmh_eligible, :chronically_homeless_for_cas, :full_housing_release, :limited_cas_release, :housing_release_status, :sync_with_cas, :hues_eligible, :disability_verified_on, :ha_eligible, :required_number_of_bedrooms, :required_minimum_occupancy, :cas_match_override, :health_prioritized, :tie_breaker_date).
        keys
    end

    def self.cas_readiness_parameters
      cas_columns.keys + [
        :housing_assistance_network_released_on,
        :vispdat_prioritization_days_homeless,
        :verified_veteran_status,
        :interested_in_set_asides,
        :rrh_desired,
        :youth_rrh_desired,
        :tc_hat_additional_days_homeless,
        :encampment_decomissioned,
        :total_homeless_nights_unsheltered,
        :service_need,
        neighborhood_interests: [],
      ]
    end

    def most_recent_pathways_or_rrh_assessment_for_destination
      @most_recent_pathways_or_rrh_assessment_for_destination ||= source_clients.map(&:most_recent_pathways_or_rrh_assessment).
        compact.
        select { |a| a.AssessmentDate.present? }.
        max_by(&:AssessmentDate)
    end

    def most_recent_pathways_assessment_for_destination
      @most_recent_pathways_assessment_for_destination ||= source_clients.map(&:most_recent_2023_pathways_assessment).
        compact.
        select { |a| a.AssessmentDate.present? }.
        max_by(&:AssessmentDate)
    end

    def most_recent_transfer_assessment_for_destination
      @most_recent_transfer_assessment_for_destination ||= source_clients.map(&:most_recent_2023_transfer_assessment).
        compact.
        select { |a| a.AssessmentDate.present? }.
        max_by(&:AssessmentDate)
    end

    def most_recent_cls
      @most_recent_cls ||= source_clients.map(&:most_recent_current_living_situation).
        compact.
        select { |a| a.InformationDate.present? }.
        max_by(&:InformationDate)
    end

    # Find the most recent TC HAT from ETO
    def most_recent_tc_hat_for_destination
      @most_recent_tc_hat_for_destination ||= source_clients.map(&:most_recent_tc_hat).
        compact.
        max_by(&:collected_at)
    end

    def active_in_cas?(include_overridden: true)
      return false if deceased? || moved_in_with_ph?

      active_by_data = case GrdaWarehouse::Config.get(:cas_available_method).to_sym
      when :cas_flag
        # Short circuit if we're using manual flag setting
        return sync_with_cas
      when :chronic
        chronics.where(chronics: { date: GrdaWarehouse::Chronic.most_recent_day }).exists?
      when :hud_chronic
        hud_chronics.where(hud_chronics: { date: GrdaWarehouse::HudChronic.most_recent_day }).exists?
      when :release_present
        any_release_on_file?
      when :active_clients
        range = GrdaWarehouse::Config.cas_sync_range
        # Homeless or Coordinated Entry
        enrollment_scope = service_history_enrollments.in_project_type([0, 1, 2, 4, 8, 14])
        if GrdaWarehouse::Config.get(:ineligible_uses_extrapolated_days)
          enrollment_scope.with_service_between(
            start_date: range.first,
            end_date: range.last,
          ).exists?
        else
          enrollment_scope.with_service_between(
            start_date: range.first,
            end_date: range.last,
            service_scope: GrdaWarehouse::ServiceHistoryService.service_excluding_extrapolated,
          ).exists?
        end
      when :project_group
        project_ids = GrdaWarehouse::Config.cas_sync_project_group&.projects&.ids
        return false unless project_ids.present?

        service_history_enrollments.ongoing.in_project(project_ids).exists?
      when :boston
        # Enrolled in project in the project group
        project_ids = GrdaWarehouse::Config.cas_sync_project_group&.projects&.ids
        project_group_scope = service_history_enrollments.ongoing
        project_group_scope = project_group_scope.in_project(project_ids) if project_ids.any?

        # current requirement:
        # 1. an ongoing enrollment at a project in the chosen group (if no group, just an ongoing enrollment)
        # 2. a release of some sort on file
        # ~3.~ Pathways or Transfer assessment on file (currently no date range restriction) (Removed by request 11/23/23)
        # project_group_scope.exists? && any_release_on_file? && most_recent_pathways_or_rrh_assessment_for_destination.present?
        project_group_scope.exists? && any_release_on_file?
      when :ce_with_assessment
        enrollment_scope = service_history_enrollments.
          in_project_type(HudUtility2024.performance_reporting[:ce]).
          ongoing.
          joins(enrollment: :assessments)
        enrollment_scope.exists?
      else
        raise NotImplementedError
      end
      return active_by_data unless include_overridden

      active_by_data || sync_with_cas
    end

    # If we aren't using the manual CAS flag method of sync-ing, but have marked the client
    # as "force sync", then also force make them available
    def force_remove_unavailable_fors
      GrdaWarehouse::Config.get(:cas_available_method).to_sym != :cas_flag && sync_with_cas
    end

    def inactivate_in_cas
      update(sync_with_cas: false)
    end

    def release_status_for_cas
      return 'None on file' if housing_release_status.blank?

      if release_duration.in?(['One Year', 'Use Expiration Date'])
        return 'Expired' unless consent_form_valid? && consent_confirmed?
      end
      return Translation.translate(housing_release_status)
    end

    private def any_release_on_file?
      [self.class.full_release_string, self.class.partial_release_string].include?(housing_release_status)
    end

    def health_prioritization_options
      {
        'Yes' => 'Yes',
        'No' => 'No',
        'Unset' => '',
      }
    end

    def health_prioritized_for_cas?
      return false unless GrdaWarehouse::Config.get(:health_priority_age).present?
      return true if age.present? && age >= GrdaWarehouse::Config.get(:health_priority_age)

      health_prioritized == 'Yes'
    end

    def auto_health_prioritized_for_cas?
      return false unless GrdaWarehouse::Config.get(:health_priority_age).present?
      return false unless age.present?

      age >= GrdaWarehouse::Config.get(:health_priority_age)
    end

    # This prevents leaking involvement in confidential cohorts
    def cohort_ids_for_cas
      GrdaWarehouse::Cohort.visible_in_cas.where(id: active_cohort_ids).pluck(:id)
    end

    def neighborhood_ids_for_cas
      neighborhood_interests.map(&:to_i)
    end

    # Should be in the format {tag_id: min_rank}
    # and returns the lowest rank for an individual for each tag
    def cas_tags
      @cas_tags = {}
      cohort_clients.joins(:cohort).
        merge(GrdaWarehouse::Cohort.where(id: cohort_ids_for_cas)).
        each do |cc|
          tag_id = cc.cohort.tag_id
          if tag_id.present?
            @cas_tags[tag_id] ||= cc.rank
            @cas_tags[tag_id] = cc.rank if cc.rank.present? && (cc.rank < @cas_tags[tag_id])
          end
        end
      # Are any tags that should be added based on HmisForms
      CasAccess::Tag.where(rrh_assessment_trigger: true)&.each do |tag|
        @cas_tags[tag.id] = assessment_score_for_cas
      end
      @cas_tags
    end

    def default_shelter_agency_contacts
      (source_hmis_forms.rrh_assessment.with_staff_contact.pluck(:staff_email) + source_hmis_forms.pathways.pluck(:staff_email)).compact
    end

    def pathways_assessments
      source_hmis_forms.pathways
    end

    def most_recent_pathways_assessment
      pathways_assessments.newest_first.first
    end

    def most_recent_pathways_assessment_collected_on
      most_recent_pathways_assessment&.collected_at
    end

    def sync_cas_attributes_with_files
      return unless GrdaWarehouse::Config.get(:cas_flag_method) == 'file'

      self.ha_eligible = client_files.tagged_with(cas_attributes_file_tag_map[:ha_eligible], any: true).exists?
      if client_files.tagged_with(cas_attributes_file_tag_map[:disability_verified_on], any: true).exists?
        # set this to the most recent updated date
        self.disability_verified_on = client_files.tagged_with(cas_attributes_file_tag_map[:disability_verified_on], any: true).
          order(updated_at: :desc).
          pluck(:updated_at).first
      else
        self.disability_verified_on = nil
      end
      save
    end

    def cas_attributes_file_tag_map
      {
        ha_eligible: [
          'BHA Eligibility',
          'Housing Authority Eligibility',
        ],
        disability_verified_on: GrdaWarehouse::AvailableFileTag.tag_includes('Verification of Disability').map(&:name),
        limited_cas_release: [
          'Limited CAS Release',
        ],
      }
    end

    def contact_info_for_rrh_assessment
      rrh_assessment_contact_info if consent_form_valid?
    end

    def score_for_rrh_assessment
      processed_service_history&.eto_coordinated_entry_assessment_score || 0
    end

    # Pathways and RRH assessment scores get stored in rrh_assessment_score
    # If we don't have that, use highest assessment score from any cohort clients
    def assessment_score_for_cas
      return rrh_assessment_score if rrh_assessment_score.present? && rrh_assessment_score.positive?

      assessment_score_from_cohort_clients
    end

    private def assessment_score_from_cohort_clients
      cohort_clients.pluck(:assessment_score)&.compact&.max || 0
    end

    private def max_current_total_monthly_income
      # To allow preload(:source_enrollments) do the open_on_date calculation in memory
      source_enrollments.select do |enrollment|
        entry_date = enrollment.EntryDate
        exit_date = enrollment.exit&.ExitDate || Date.tomorrow
        Date.current.between?(entry_date, exit_date)
      end.map do |enrollment|
        enrollment.income_benefits.select { |m| m.InformationDate.present? }&.
          max_by(&:InformationDate)&.TotalMonthlyIncome
      end.compact.max || 0
    end

    private def days_homeless_in_last_three_years_cached
      processed_service_history&.days_homeless_last_three_years
    end

    private def literally_homeless_last_three_years_cached
      processed_service_history&.literally_homeless_last_three_years
    end

    private def days_homeless_for_vispdat_prioritization
      vispdat_prioritization_days_homeless || days_homeless_in_last_three_years_cached || 0
    end

    private def hmis_days_homeless_in_last_three_years
      processed_service_history&.days_homeless_last_three_years
    end

    private def hmis_days_homeless_all_time
      processed_service_history&.homeless_days
    end

    # Default to a generic CE assessment, identified since it comes from HMIS
    private def cas_assessment_name
      'IdentifedCeAssessment'
    end

    def self.ongoing_enrolled_project_details(client_ids)
      {}.tap do |ids|
        GrdaWarehouse::ServiceHistoryEnrollment.where(client_id: client_ids).
          ongoing.
          joins(:project).
          pluck(:client_id, p_t[:id], GrdaWarehouse::ServiceHistoryEnrollment.project_type_column, :move_in_date).
          each do |c_id, p_id, p_type, move_in_date|
            ids[c_id] ||= []
            ids[c_id] << OpenStruct.new(project_id: p_id, project_type: p_type, move_in_date: move_in_date)
          end
      end
    end

    def enrolled_in_rrh(ongoing_enrollments)
      return false unless ongoing_enrollments

      project_type_codes = [13]
      ongoing_enrollments.select do |en|
        en.project_type.in?(project_type_codes) &&
        en.move_in_date.present? && en.move_in_date < Date.current
      end.any?
    end

    def enrolled_in_psh(ongoing_enrollments)
      return false unless ongoing_enrollments

      project_type_codes = [3]
      ongoing_enrollments.select do |en|
        en.project_type.in?(project_type_codes) &&
        en.move_in_date.present? && en.move_in_date < Date.current
      end.any?
    end

    def enrolled_in_ph(ongoing_enrollments)
      return false unless ongoing_enrollments

      project_type_codes = [9, 10]
      ongoing_enrollments.select do |en|
        en.project_type.in?(project_type_codes) &&
        en.move_in_date.present? && en.move_in_date < Date.current
      end.any?
    end

    def enrolled_in_rrh_pre_move_in(ongoing_enrollments)
      return false unless ongoing_enrollments

      project_type_codes = [13]
      ongoing_enrollments.select do |en|
        en.project_type.in?(project_type_codes) &&
        en.move_in_date.blank?
      end.any?
    end

    def enrolled_in_psh_pre_move_in(ongoing_enrollments)
      return false unless ongoing_enrollments

      project_type_codes = [3]
      ongoing_enrollments.select do |en|
        en.project_type.in?(project_type_codes) &&
        en.move_in_date.blank?
      end.any?
    end

    def enrolled_in_ph_pre_move_in(ongoing_enrollments)
      return false unless ongoing_enrollments

      project_type_codes = [9, 10]
      ongoing_enrollments.select do |en|
        en.project_type.in?(project_type_codes) &&
        en.move_in_date.blank?
      end.any?
    end

    def enrolled_in_th(ongoing_enrollments)
      return false unless ongoing_enrollments

      project_type_codes = HudUtility2024.residential_project_type_numbers_by_code[:th]
      ongoing_enrollments.select do |en|
        en.project_type.in?(project_type_codes)
      end.any?
    end

    def enrolled_in_sh(ongoing_enrollments)
      return false unless ongoing_enrollments

      project_type_codes = HudUtility2024.residential_project_type_numbers_by_code[:sh]
      ongoing_enrollments.select do |en|
        en.project_type.in?(project_type_codes)
      end.any?
    end

    def enrolled_in_so(ongoing_enrollments)
      return false unless ongoing_enrollments

      project_type_codes = HudUtility2024.residential_project_type_numbers_by_code[:so]
      ongoing_enrollments.select do |en|
        en.project_type.in?(project_type_codes)
      end.any?
    end

    def enrolled_in_es(ongoing_enrollments)
      return false unless ongoing_enrollments

      project_type_codes = HudUtility2024.residential_project_type_numbers_by_code[:es]
      ongoing_enrollments.select do |en|
        en.project_type.in?(project_type_codes)
      end.any?
    end

    def cas_assessment_collected_at
      rrh_assessment_collected_at
    end

    # The following do not currently get persisted onto Client, but are calculated live
    attr_accessor :majority_sheltered,
                  :tie_breaker_date,
                  :financial_assistance_end_date,
                  :strengths,
                  :challenges,
                  :foster_care,
                  :open_case,
                  :housing_for_formerly_homeless,
                  :hivaids_status,
                  :drug_test,
                  :heavy_drug_use,
                  :sober,
                  :willing_case_management,
                  :employed_three_months,
                  :living_wage,
                  :need_daily_assistance,
                  :full_time_employed,
                  :can_work_full_time,
                  :willing_to_work_full_time,
                  :rrh_successful_exit,
                  :th_desired,
                  :drug_test,
                  :employed_three_months,
                  :site_case_management_required,
                  :ongoing_case_management_required,
                  :currently_fleeing,
                  :dv_date,
                  :assessor_first_name,
                  :assessor_last_name,
                  :assessor_email,
                  :assessor_phone,
                  :match_group,
                  :total_homeless_nights_unsheltered,
                  :service_need,
                  :housing_barrier,
                  :additional_homeless_nights_sheltered,
                  :additional_homeless_nights_unsheltered,
                  :calculated_homeless_nights_sheltered,
                  :calculated_homeless_nights_unsheltered,
                  :total_homeless_nights_sheltered
  end
end
