###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOTE: This report runs all calculations against the most-recently started enrollment
# that matches the filter scope for a given client
module IncomeBenefitsReport
  class Report
    include Filter::ControlSections
    include Filter::FilterScopes
    include ActionView::Helpers::NumberHelper
    include ArelHelper
    include IncomeBenefitsReport::Details
    include IncomeBenefitsReport::Summary
    include IncomeBenefitsReport::StayerHouseholds

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
      'income_benefits_report/warehouse_reports/report'
    end

    def self.available_section_types
      [
        'summary',
        'stayers_households',
        'leavers_households',
        'stayers_income_sources',
        'stayers_non_cash_benefits_sources',
        'stayers_insurance_sources',
        'leavers_income_sources',
        'leavers_non_cash_benefits_sources',
        'leavers_insurance_sources',
      ]
    end

    def section_ready?(section)
      return true unless section.in?(['summary', 'stayers_households'])

      Rails.cache.exist?(cache_key_for_section(section))
    end

    private def cache_key_for_section(section)
      [self.class.name, cache_slug, section]
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
        :income_benefits_report,
        :warehouse_reports,
        :report,
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
      scope = filter_for_chronic_status(scope)
      scope = filter_for_ca_homeless(scope)

      # Limit to most recently started enrollment per client
      scope.only_most_recent_by_client(scope: scope)
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

    private def hoh_scope
      report_scope.where(she_t[:head_of_household].eq(true))
    end

    # Anyone with at least one open enrollment on the last day of the report
    private def filter_for_stayers(scope)
      scope.where(client_id: report_scope.open_between(start_date: @filter.end_date, end_date: @filter.end_date).select(:client_id))
    end

    # Anyone who doesn't have at least one open enrollment on the last day of the report
    private def filter_for_leavers(scope)
      scope.where.not(client_id: report_scope.open_between(start_date: @filter.end_date, end_date: @filter.end_date).select(:client_id))
    end

    private def filter_for_adults(scope)
      scope.joins(:client).where(c_t[:DOB].lt(Arel.sql("GREATEST('#{(@filter.start_date - 18.years).to_s(:db)}', #{she_t[:first_date_in_program].to_sql} - interval '18 years')")))
    end

    private def filter_for_children(scope)
      scope.joins(:client).where(c_t[:DOB].gteq(Arel.sql("GREATEST('#{(@filter.start_date - 18.years).to_s(:db)}', #{she_t[:first_date_in_program].to_sql} - interval '18 years')")))
    end

    private def distinct_client_ids
      report_scope.select(:client_id).distinct
    end

    private def cache_slug
      @filter.attributes
    end

    private def expiration_length
      return 300.seconds if Rails.env.development?

      30.minutes
    end
  end
end
