###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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

    def self.cas_columns
      @cas_columns ||= {
        disability_verified_on: _('Disability Verification on File'),
        housing_release_status: _('Housing Release Status'),
        full_housing_release: _('Full HAN Release on File'),
        limited_cas_release: _('Limited CAS Release on File'),
        sync_with_cas: _('Available for matching in CAS'),
        dmh_eligible: _('DMH Eligible'),
        va_eligible: _('VA Eligible'),
        hues_eligible: _('HUES Eligible'),
        hiv_positive: _('HIV+'),
        chronically_homeless_for_cas: _('Chronically Homeless for CAS'),
        us_citizen: _('U.S Citizen or Permanent Resident'),
        asylee: _('Asylee, Refugee'),
        ineligible_immigrant: _('Ineligible Immigrant (Including Undocumented)'),
        lifetime_sex_offender: _('Life-Time Sex Offender'),
        meth_production_conviction: _('Meth Production Conviction'),
        family_member: _('Part of a family'),
        child_in_household: _('Children under age 18 in household'),
        ha_eligible: _('Housing Authority Eligible'),
        cspech_eligible: _('CSPECH Eligible'),
        congregate_housing: _('Willing to live in congregate housing'),
        sober_housing: _('Appropriate for sober supportive housing'),
        requires_wheelchair_accessibility: _('Requires wheelchair accessible unit'),
        required_number_of_bedrooms: _('Minimum number of bedrooms'),
        required_minimum_occupancy: _('Minimum occupancy'),
        requires_elevator_access: _('Requires ground floor unit or elevator access'),
        cas_match_override: _('Override CAS Match Date'),
        vash_eligible: _('VASH Eligible'),
        health_prioritized: _('Health Priority'),
        tie_breaker_date: _('Tie Breaker Date'),
        financial_assistance_end_date: _('Financial Assistance End Date'),
        strengths: _('Strengths'),
        challenges: _('Challenges'),
        foster_care: _('Foster care as youth'),
        open_case: _('Current open case'),
        housing_for_formerly_homeless: _('Prefers housing for formerly homeless'),
        drug_test: _('Able to pass a drug test'),
        heavy_drug_use: _('History of heavy drug use'),
        sober: _('Clean/sober for at least one year'),
        willing_case_management: _('Willing to engage with housing case management'),
        employed_three_months: _('Employed for 3 or more months'),
        living_wage: _('Earning a living wage ($13 or more)'),
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
      cas_columns.except(:hiv_positive, :dmh_eligible, :chronically_homeless_for_cas, :full_housing_release, :limited_cas_release, :housing_release_status, :sync_with_cas, :hues_eligible, :disability_verified_on, :required_number_of_bedrooms, :required_minimum_occupancy, :cas_match_override, :health_prioritized, :tie_breaker_date).
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
        neighborhood_interests: [],
      ]
    end

    def most_recent_pathways_or_rrh_assessment_for_destination
      @most_recent_pathways_or_rrh_assessment_for_destination ||= source_clients.map(&:most_recent_pathways_or_rrh_assessment).
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

    def most_recent_tc_hat_for_destination
      @most_recent_tc_hat_for_destination ||= source_clients.map(&:most_recent_tc_hat).
        compact.
        max_by(&:collected_at)
    end

    def active_in_cas?
      return false if deceased? || moved_in_with_ph?

      case GrdaWarehouse::Config.get(:cas_available_method).to_sym
      when :cas_flag
        sync_with_cas
      when :chronic
        chronics.where(chronics: { date: GrdaWarehouse::Chronic.most_recent_day }).exists?
      when :hud_chronic
        hud_chronics.where(hud_chronics: { date: GrdaWarehouse::HudChronic.most_recent_day }).exists?
      when :release_present
        [self.class.full_release_string, self.class.partial_release_string].include?(housing_release_status)
      when :active_clients
        range = GrdaWarehouse::Config.cas_sync_range
        # Homeless or Coordinated Assessment
        enrollment_scope = service_history_enrollments.in_project_type([1, 2, 4, 8, 14])
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
      else
        raise NotImplementedError
      end
    end

    def inactivate_in_cas
      update(sync_with_cas: false)
    end

    def release_status_for_cas
      return 'None on file' if housing_release_status.blank?

      if release_duration.in?(['One Year', 'Use Expiration Date'])
        return 'Expired' unless consent_form_valid? && consent_confirmed?
      end
      return _(housing_release_status)
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
      Cas::Tag.where(rrh_assessment_trigger: true).each do |tag|
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

    # Use the Pathways value if it is present and non-zero
    # Otherwise, pull the maximum total monthly income from any open enrollments, looking
    # only at the most recent assessment per enrollment
    private def max_current_total_monthly_income
      return income_total_monthly if income_total_monthly.present? && income_total_monthly.positive?

      source_enrollments.open_on_date(Date.current).map do |enrollment|
        enrollment.income_benefits.limit(1).
          order(InformationDate: :desc).
          pluck(:TotalMonthlyIncome).first
      end.compact.max || 0
    end

    private def days_homeless_in_last_three_years_cached
      processed_service_history&.days_homeless_last_three_years
    end

    private def literally_homeless_last_three_years_cached
      processed_service_history&.literally_homeless_last_three_years
    end

    private def days_homeless_for_vispdat_prioritization
      vispdat_prioritization_days_homeless || days_homeless_in_last_three_years
    end

    # Default to the original assessment, identified since it comes from HMIS
    private def cas_assessment_name
      'IdentifiedClientAssessment'
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

    def enrolled_in_th(ongoing_enrollments)
      return false unless ongoing_enrollments

      project_type_codes = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:th]
      ongoing_enrollments.select do |en|
        en.project_type.in?(project_type_codes)
      end.any?
    end

    def enrolled_in_sh(ongoing_enrollments)
      return false unless ongoing_enrollments

      project_type_codes = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:sh]
      ongoing_enrollments.select do |en|
        en.project_type.in?(project_type_codes)
      end.any?
    end

    def enrolled_in_so(ongoing_enrollments)
      return false unless ongoing_enrollments

      project_type_codes = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:so]
      ongoing_enrollments.select do |en|
        en.project_type.in?(project_type_codes)
      end.any?
    end

    def enrolled_in_es(ongoing_enrollments)
      return false unless ongoing_enrollments

      project_type_codes = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:es]
      ongoing_enrollments.select do |en|
        en.project_type.in?(project_type_codes)
      end.any?
    end

    def cas_assessment_collected_at
      rrh_assessment_collected_at
    end

    # The following do not currently get persisted onto Client, but are calculated live
    attr_accessor :majority_sheltered, :tie_breaker_date, :financial_assistance_end_date, :strengths, :challenges, :foster_care, :open_case, :housing_for_formerly_homeless, :hivaids_status, :drug_test, :heavy_drug_use, :sober, :willing_case_management, :employed_three_months, :living_wage, :assessor_first_name, :assessor_last_name, :assessor_email, :assessor_phone
  end
end
