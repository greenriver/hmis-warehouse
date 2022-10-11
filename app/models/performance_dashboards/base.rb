###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class PerformanceDashboards::Base
  include ArelHelper
  include ActionView::Helpers::NumberHelper
  include Filter::ControlSections
  include Filter::FilterScopes

  # Initialize dashboard model.
  #
  # @param start_date [Date]
  # @param end_date [Date]
  # @param coc_codes [Array<String>] when blank, defaults to all CoCs
  # @param household_type [Symbol], when blank defaults to any household type :without_children, :with_children, :only_children)
  # @param hoh_only [Boolean]
  # @param age_ranges [Array<Symbol>], when blank, defaults to any age (:under_eighteen, :eighteen_to_twenty_four, :twenty_five_to_sixty_one, :over_sixty_one)
  # @param genders [Array<Integer>] uses HUD gender values, when blank defaults to any gender
  # @param races [Hash<String=>Integer>] uses HUD race keys and values, when blank, defaults to any race
  # @param ethnicities [Array<Integer>] uses HUD ethnicity values, when blank, defaults to any ethnicity
  # @param veteran_statuses [Array<Integer] uses HUD options, when blank, default to any status
  # @param project_types [Array<Integer>] uses HUD options, when blank, defaults to [ES, SO, TH, SH]
  def initialize(filter)
    @filter = filter
    @start_date = filter.start_date
    @end_date = filter.end_date
    @coc_codes = filter.coc_codes
    @household_type = filter.household_type
    @hoh_only = filter.hoh_only
    @age_ranges = filter.age_ranges
    @length_of_times = filter.length_of_times
    @genders = filter.genders
    @races = filter.races
    @ethnicities = filter.ethnicities
    @veteran_statuses = filter.veteran_statuses
    @project_types = filter.project_type_ids || GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
    @comparison_pattern = filter.comparison_pattern
    @sub_population = valid_sub_population(filter.sub_population)
  end

  attr_reader :start_date, :end_date, :coc_codes, :project_types, :filter
  attr_accessor :comparison_pattern, :project_type_codes

  def self.viewable_by(user)
    GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
      viewable_by(user).exists?
  end

  def performance_type
    'Client'
  end

  def multiple_project_types?
    true
  end

  def detail_link_base
    "#{section_subpath}details"
  end

  def section_subpath
    "#{self.class.url}/"
  end

  def filter_path_array
    [:filters] + report_path_array
  end

  def detail_path_array
    [:details] + report_path_array
  end

  private def cache_slug
    @filter.attributes
  end

  def detail_params
    @filter.for_params.
      deep_merge(filters: { comparison_pattern: :no_comparison_period })
  end

  def self.detail_method(key)
    available_keys[key.to_sym]
  end

  def household_types
    @filter.available_household_types
  end

  def household_type(type)
    @filter.household_type_string(type)
  end

  def self.coc_codes
    GrdaWarehouse::Hud::ProjectCoc.distinct.pluck(:CoCCode, :hud_coc_code).flatten.map(&:presence).compact
  end

  def include_comparison?
    comparison_pattern != :no_comparison_period
  end

  def chosen_ages
    @filter.age_ranges
  end

  def self.comparison_patterns
    {
      no_comparison_period: 'None',
      prior_year: 'Same period, prior year',
      prior_period: 'Prior Period',
    }.invert.freeze
  end

  def self.valid_comparison_pattern?(pattern)
    comparison_patterns.values.include?(pattern&.to_sym)
  end

  def self.sub_populations
    AvailableSubPopulations.available_sub_populations
    # Reporting::MonthlyReports::Base.available_types.map { |k, klass| [klass.constantize.new.sub_population_title, k] }.to_h
  end

  def valid_sub_population(population)
    self.class.sub_populations.values.detect { |m| m == population&.to_sym } || :clients
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
    scope = filter_for_prior_living_situation(scope)
    scope = filter_for_destination(scope)
    scope = filter_for_ca_homeless(scope)
    scope = filter_for_times_homeless(scope)
    scope = filter_for_ce_cls_homeless(scope)
    scope = filter_for_cohorts(scope)
    scope
  end

  def report_scope_source
    GrdaWarehouse::ServiceHistoryEnrollment.entry
  end

  def yn(boolean)
    boolean ? 'Yes' : 'No'
  end

  # An entry is an enrollment where the entry date is within the report range, and there are no entries in the
  # specified project types for specified inactivity period (default is 24 months).
  def entries
    # Use month duration to handle leap years
    inactivity_duration = @filter.inactivity_days > 90 ? @filter.inactivity_days.days.in_months.round.months : @filter.inactivity_days.days
    previous_period = report_scope_source.entry.
      open_between(start_date: @filter.start_date - inactivity_duration, end_date: @filter.start_date - 1.day).
      with_service_between(start_date: @filter.start_date - inactivity_duration, end_date: @filter.start_date - 1.day).
      in_project_type(@project_types)
    # To make this performant, we'll manipulate these a bit

    entries_current_period.where.not(period_exists_sql(previous_period))
  end

  def entries_current_period
    report_scope.entry_within_date_range(start_date: @filter.start_date, end_date: @filter.end_date).
      with_service_between(start_date: @filter.start_date, end_date: @filter.end_date)
  end

  # An exit is an enrollment where the exit date is within the report range, and there are no enrollments in the
  # specified project types that were open after the reporting period.
  def exits
    next_period = report_scope_source.entry.
      open_between(start_date: @filter.end_date + 1.day, end_date: Date.current).
      with_service_between(start_date: @filter.end_date + 1.day, end_date: Date.current).
      in_project_type(@project_types)

    exits_current_period.where.not(period_exists_sql(next_period))
  end

  def exits_current_period
    report_scope.exit_within_date_range(start_date: @filter.start_date, end_date: @filter.end_date).
      with_service_between(start_date: @filter.start_date, end_date: @filter.end_date)
  end

  def open_enrollments
    report_scope.open_between(start_date: @filter.start_date, end_date: @filter.end_date)
  end

  private def period_exists_sql(period)
    exists_sql(period, quoted_table_name: report_scope_source.quoted_table_name, alias_name: 'she_2', column_name: 'client_id')
  end
end
