###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CoreDemographicsReport
  class Core
    include Filter::ControlSections
    include Filter::FilterScopes
    include ActionView::Helpers::NumberHelper
    include ArelHelper
    include CoreDemographicsReport::AgeCalculations
    include CoreDemographicsReport::GenderCalculations
    include CoreDemographicsReport::RaceCalculations
    include CoreDemographicsReport::EthnicityCalculations
    include CoreDemographicsReport::DisabilityCalculations
    include CoreDemographicsReport::RelationshipCalculations
    include CoreDemographicsReport::DvCalculations
    include CoreDemographicsReport::PriorCalculations
    include CoreDemographicsReport::HouseholdTypeCalculations
    include CoreDemographicsReport::Projects
    include CoreDemographicsReport::Details

    attr_reader :filter
    attr_accessor :comparison_pattern, :project_type_codes

    def initialize(filter)
      @filter = filter
      @project_types = filter.project_type_ids || GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
      @comparison_pattern = filter.comparison_pattern
    end

    def self.comparison_patterns
      {
        no_comparison_period: 'None',
        prior_year: 'Same period, prior year',
        prior_period: 'Prior Period',
      }.invert.freeze
    end

    def self.viewable_by(user)
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
        viewable_by(user).exists?
    end

    def self.url
      'core_demographics_report/warehouse_reports/core'
    end

    def self.available_section_types
      [
        'ages',
        'genders',
        'gender_ages',
        'races',
        'ethnicities',
        'disabilities',
        'relationships',
        'dvs',
        'priors',
        'household_types',
        'projects',
      ]
    end

    def section_ready?(section)
      return true unless section.in?(['disabilities', 'races'])

      Rails.cache.exist?(cache_key_for_section(section))
    end

    private def cache_key_for_section(section)
      case section
      when 'disabilities'
        disabilities_cache_key
      when 'races'
        races_cache_key
      end
    end

    def multiple_project_types?
      true
    end

    protected def build_control_sections
      [
        build_general_control_section,
        build_coc_control_section,
        build_household_control_section,
        add_demographic_disabilities_control_section,
      ]
    end

    def report_path_array
      [
        :core_demographics_report,
        :warehouse_reports,
        :core,
        :index,
      ]
    end

    def filter_path_array
      [:filters] + report_path_array
    end

    def include_comparison?
      comparison_pattern != :no_comparison_period
    end

    # @return filtered scope
    def report_scope(all_project_types: false)
      # Report range
      scope = report_scope_source
      scope = filter_for_user_access(scope)
      scope = filter_for_range(scope)
      scope = filter_for_cocs(scope)
      scope = filter_for_sub_population(scope)
      scope = filter_for_household_type(scope)
      scope = filter_for_head_of_household(scope)
      scope = filter_for_age(scope)
      scope = filter_for_gender(scope)
      scope = filter_for_race(scope)
      scope = filter_for_ethnicity(scope)
      scope = filter_for_veteran_status(scope)
      scope = filter_for_project_type(scope, all_project_types: all_project_types)
      scope = filter_for_data_sources(scope)
      scope = filter_for_organizations(scope)
      scope = filter_for_projects(scope)
      scope = filter_for_funders(scope)
      scope = filter_for_disabilities(scope)
      scope = filter_for_indefinite_disabilities(scope)
      scope = filter_for_dv_status(scope)
      scope = filter_for_chronic_at_entry(scope)
      scope = filter_for_times_homeless(scope)
      scope = filter_for_ca_homeless(scope)
      scope = filter_for_ce_cls_homeless(scope)
      scope
    end

    def report_scope_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry
    end

    def yn(boolean)
      boolean ? 'Yes' : 'No'
    end

    def total_client_count
      @total_client_count ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        distinct_client_ids.count
      end
    end

    def hoh_count
      @hoh_count ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        hoh_scope.select(:client_id).distinct.count
      end
    end

    def household_count
      @household_count ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        report_scope.select(:household_id).distinct.count
      end
    end

    def project_count
      @project_count ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        report_scope.select(p_t[:id]).distinct.count
      end
    end

    def can_see_client_details?(user)
      user.can_access_some_version_of_clients?
    end

    def self.data_for_export(reports)
      {}.tap do |rows|
        reports.each do |report|
          rows['Date Range'] ||= []
          rows['Date Range'] += [report.filter.date_range_words, nil, nil, nil]
          rows['Unique Clients'] ||= []
          rows['Unique Clients'] += [report.total_client_count, nil, nil, nil]
          rows['Heads of Household'] ||= []
          rows['Heads of Household'] += [report.hoh_count, nil, nil, nil]
          rows['Households'] ||= []
          rows['Households'] += [report.household_count, nil, nil, nil]

          rows = report.age_data_for_export(rows)
          rows = report.gender_data_for_export(rows)
          rows = report.race_data_for_export(rows)
          rows = report.ethnicity_data_for_export(rows)
          rows = report.relationship_data_for_export(rows)
          rows = report.disability_data_for_export(rows)
          rows = report.dv_status_data_for_export(rows)
          rows = report.priors_data_for_export(rows)
          rows = report.household_type_data_for_export(rows)
          rows = report.enrollment_data_for_export(rows)
        end
      end
    end

    private def hoh_scope
      report_scope.where(she_t[:head_of_household].eq(true))
    end

    private def distinct_client_ids
      report_scope.select(:client_id).distinct
    end

    private def adult_clause
      age_calculation.in((18..110).to_a)
    end

    private def child_clause
      age_calculation.in((0..17).to_a)
    end

    private def male_clause
      c_t[:Male].eq(1)
    end

    private def female_clause
      c_t[:Female].eq(1)
    end

    private def trans_clause
      c_t[:Transgender].eq(1)
    end

    private def questioning_clause
      c_t[:Questioning].eq(1)
    end

    private def no_single_gender_clause
      c_t[:NoSingleGender].eq(1)
    end

    private def unknown_gender_clause
      c_t[:GenderNone].in([8, 9, 99])
    end

    private def average_age(clause:)
      average_age = nf('AVG', [age_calculation])
      scope = report_scope.joins(:client).where(clause)
      scope.joins(:client).pluck(average_age)&.first&.to_i
    end

    private def cache_slug
      @filter.attributes
    end

    private def expiration_length
      return 30.seconds if Rails.env.development?

      30.minutes
    end
  end
end
