###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class PerformanceDashboards::Base # rubocop:disable Style/ClassAndModuleChildren
  include ArelHelper

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

  def client_filters?
    true
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

  def control_sections
    @control_sections ||= build_control_sections
  end

  protected def build_control_sections
    [
      build_general_control_section,
      build_coc_control_section,
      build_household_control_section,
      build_demographics_control_section,
      build_enrollment_control_section,
    ]
  end

  protected def build_general_control_section
    ::Filters::UiControlSection.new(id: 'general').tap do |section|
      section.add_control(
        id: 'project_types',
        required: true,
        label: 'Population by Project Type',
        short_label: 'Project Type',
        value: describe_household_control_section,
      )
      section.add_control(id: 'reporting_period', required: true, value: date_range_words)
      section.add_control(id: 'comparison_period', value: nil)
    end
  end

  protected def describe_household_control_section
    if chosen_project_types_only_homeless?
      'Only Homeless'
    elsif filter.project_type_codes.sort == GrdaWarehouse::Hud::Project::PROJECT_GROUP_TITLES.keys.map(&:to_s).sort
      'All'
    else
      chosen_project_types
    end
  end

  protected def build_coc_control_section
    title = if GrdaWarehouse::Config.get(:multi_coc_installation)
      'CoC & Funding'
    else
      'Projects & Funding'
    end
    ::Filters::UiControlSection.new(id: 'coc', title: title).tap do |section|
      if GrdaWarehouse::Config.get(:multi_coc_installation)
        section.add_control(
          id: 'coc_codes',
          label: 'CoC Codes',
          short_label: 'CoC',
          value: chosen_coc_codes,
        )
      end
      section.add_control(id: 'funding_sources', value: funder_names)
      section.add_control(id: 'data_sources', value: data_source_names)
      section.add_control(id: 'organizations', value: organization_names)
      section.add_control(id: 'projects', value: project_names)
      section.add_control(id: 'project_groups', value: project_groups)
    end
  end

  protected def build_household_control_section
    ::Filters::UiControlSection.new(id: 'household').tap do |section|
      section.add_control(id: 'household_type', required: true, value: @filter.household_type == :all ? nil : chosen_household_type)
      if performance_type == 'Client'
        section.add_control(
          id: 'hoh_only',
          label: 'Only Heads of Household?',
          value: @filter.hoh_only ? 'HOH Only' : nil,
        )
      end
    end
  end

  protected def build_demographics_control_section
    ::Filters::UiControlSection.new(id: 'demographics').tap do |section|
      section.add_control(
        id: 'sub_population',
        label: 'Sub-Population',
        short_label: 'Sub-Population',
        required: true,
        value: @filter.sub_population == :clients ? nil : chosen_sub_population,
      )
      if performance_type == 'Client'
        section.add_control(id: 'races', value: chosen_races, short_label: 'Race')
        section.add_control(id: 'ethnicities', value: chosen_ethnicities, short_label: 'Ethnicity')
        section.add_control(id: 'age_ranges', value: chosen_age_ranges, short_label: 'Age')
        section.add_control(
          id: 'genders',
          short_label: 'Gender',
          value: chosen_genders,
        )
        section.add_control(
          id: 'veteran_statuses',
          short_label: 'Veteran Status',
          value: chosen_veteran_statuses,
        )
      end
    end
  end

  protected def build_enrollment_control_section
    return if multiple_project_types?

    ::Filters::UiControlSection.new(id: 'enrollment').tap do |section|
      section.add_control(id: 'prior_living_situations', value: chosen_prior_living_situations)
      section.add_control(id: 'destinations', value: chosen_destinations)
    end
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

  def self.coc_codes
    GrdaWarehouse::Hud::ProjectCoc.distinct.pluck(:CoCCode)
  end

  def include_comparison?
    comparison_pattern != :no_comparison_period
  end

  def household_types
    {
      all: 'All household types',
      without_children: 'Adult only Households',
      with_children: 'Adult and Child Households',
      only_children: 'Child only Households',
    }.invert.freeze
  end

  def household_type(type)
    household_types.invert[type] || 'Unknown'
  end

  def age_ranges
    {
      under_eighteen: '< 18',
      eighteen_to_twenty_four: '18 - 24',
      twenty_five_to_twenty_nine: '25 - 29',
      thirty_to_thirty_nine: '30 - 39',
      forty_to_forty_nine: '40 - 49',
      fifty_to_fifty_nine: '50 - 59',
      sixty_to_sixty_one: '60 - 61',
      over_sixty_one: '62+',
    }.invert.freeze
  end

  def available_prior_living_situations
    HUD.living_situations.invert
  end

  def available_destinations
    HUD.valid_destinations.invert
  end

  def available_data_sources_for_select
    GrdaWarehouse::DataSource.viewable_by(@filter.user).options_for_select(user: @filter.user)
  end

  def data_source_names
    available_data_sources_for_select.select { |_, id| @filter.data_source_ids.include?(id) }&.map(&:first)
  end

  def available_organizations_for_select
    GrdaWarehouse::Hud::Organization.viewable_by(@filter.user).options_for_select(user: @filter.user)
  end

  def organization_names
    available_organizations_for_select.values.flatten(1).select { |_, id| @filter.organization_ids.include?(id) }&.map(&:first)
  end

  def available_projects_for_select
    GrdaWarehouse::Hud::Project.viewable_by(@filter.user).options_for_select(user: @filter.user)
  end

  def project_names
    available_projects_for_select.values.flatten(1).select { |_, id| @filter.project_ids.include?(id) }&.map(&:first)
  end

  def project_groups
    available_project_groups_for_select.select { |_, id| @filter.project_group_ids.include?(id) }&.map(&:first)
  end

  def available_project_groups_for_select
    GrdaWarehouse::ProjectGroup.options_for_select(user: @filter.user)
  end

  def available_cocs_for_select
    GrdaWarehouse::Lookups::CocCode.options_for_select(user: @filter.user)
  end

  def available_funders_for_select
    GrdaWarehouse::Hud::Funder.options_for_select(user: @filter.user)
  end

  def funder_names
    available_funders_for_select.select { |_, id| @filter.funder_ids.include?(id.to_i) }&.map(&:first)
  end

  def chosen_ages
    @age_ranges
  end

  def chosen_age_ranges
    @age_ranges.map do |range|
      age_ranges.invert[range]
    end.join(', ')
  end

  def chosen_genders
    @genders.map do |gender|
      HUD.gender(gender)
    end
  end

  def chosen_coc_codes
    @coc_codes.join(', ')
  end

  def chosen_veteran_statuses
    @veteran_statuses.map do |veteran_status|
      HUD.veteran_status(veteran_status)
    end
  end

  def chosen_project_types
    @project_types.map do |type|
      HUD.project_type(type)
    end.uniq
  end

  def chosen_project_types_only_homeless?
    filter.project_type_ids.sort == GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES.sort
  end

  def chosen_household_type
    household_type(@household_type.to_sym)
  end

  def chosen_sub_population
    Reporting::MonthlyReports::Base.available_types[@sub_population]&.constantize&.new&.sub_population_title
  end

  def chosen_races
    @races.map do |race|
      HUD.race(race)
    end
  end

  def chosen_ethnicities
    @ethnicities.map do |ethnicity|
      HUD.ethnicity(ethnicity)
    end
  end

  def chosen_prior_living_situations
    @filter.prior_living_situation_ids.map do |id|
      available_prior_living_situations.invert[id]
    end.join(', ')
  end

  def chosen_destinations
    @filter.destination_ids.map do |id|
      available_destinations.invert[id]
    end.join(', ')
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
    Reporting::MonthlyReports::Base.available_types.map { |k, klass| [klass.constantize.new.sub_population_title, k] }.to_h
  end

  def valid_sub_population(population)
    self.class.sub_populations.values.detect { |m| m == population&.to_sym } || :clients
  end

  # @return filtered scope
  def report_scope(all_project_types: false)
    # Report range
    scope = filter_for_range(report_scope_source)
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
    scope
  end

  private def filter_for_range(scope)
    scope.open_between(start_date: @start_date, end_date: @end_date).
      with_service_between(start_date: @start_date, end_date: @end_date)
  end

  private def filter_for_cocs(scope)
    return scope unless @coc_codes.present?

    scope.joins(:enrollment_coc_at_entry).
      where(ec_t[:CoCCode].in(@coc_codes))
  end

  private def filter_for_household_type(scope)
    return scope unless @household_type.present? && @household_type != :all

    case @household_type
    when :without_children
      scope.adult_only_households
    when :with_children
      scope.adults_with_children
    when :only_children
      scope.child_only_households
    end
  end

  private def filter_for_head_of_household(scope)
    return scope unless @hoh_only

    scope.where(she_t[:head_of_household].eq(true))
  end

  private def filter_for_age(scope)
    return scope unless @age_ranges.present? && (age_ranges.values & @age_ranges).present?

    # Or'ing ages is very slow, instead we'll build up an acceptable
    # array of ages
    ages = []
    ages += (0..17).to_a if @age_ranges.include?(:under_eighteen)
    ages += (18..24).to_a if @age_ranges.include?(:eighteen_to_twenty_four)
    ages += (25..29).to_a if @age_ranges.include?(:twenty_five_to_twenty_nine)
    ages += (30..39).to_a if @age_ranges.include?(:thirty_to_thirty_nine)
    ages += (40..49).to_a if @age_ranges.include?(:forty_to_forty_nine)
    ages += (50..59).to_a if @age_ranges.include?(:fifty_to_fifty_nine)
    ages += (60..61).to_a if @age_ranges.include?(:sixty_to_sixty_one)
    ages += (62..110).to_a if @age_ranges.include?(:over_sixty_one)
    scope.where(she_t[:age].in(ages))
  end

  private def filter_for_gender(scope)
    return scope unless @genders.present?

    scope.joins(:client).where(c_t[:Gender].in(@genders))
  end

  private def filter_for_race(scope)
    return scope unless @races.present?

    keys = @races
    race_scope = nil
    race_scope = add_alternative(race_scope, race_alternative(:AmIndAKNative)) if keys.include?('AmIndAKNative')
    race_scope = add_alternative(race_scope, race_alternative(:Asian)) if keys.include?('Asian')
    race_scope = add_alternative(race_scope, race_alternative(:BlackAfAmerican)) if keys.include?('BlackAfAmerican')
    race_scope = add_alternative(race_scope, race_alternative(:NativeHIOtherPacific)) if keys.include?('NativeHIOtherPacific')
    race_scope = add_alternative(race_scope, race_alternative(:White)) if keys.include?('White')
    race_scope = add_alternative(race_scope, race_alternative(:RaceNone)) if keys.include?('RaceNone')

    scope.merge(race_scope)
  end

  private def filter_for_ethnicity(scope)
    return scope unless @ethnicities.present?

    scope.joins(:client).where(c_t[:Ethnicity].in(@ethnicities))
  end

  private def filter_for_veteran_status(scope)
    return scope unless @veteran_statuses.present?

    scope.joins(:client).where(c_t[:VeteranStatus].in(@veteran_statuses))
  end

  private def filter_for_project_type(scope, all_project_types: nil)
    return scope if all_project_types

    scope.in_project_type(@project_types)
  end

  private def filter_for_projects(scope)
    return scope if @filter.project_ids.blank? && @filter.project_group_ids.blank?

    project_ids = @filter.project_ids || []
    project_groups = GrdaWarehouse::ProjectGroup.find(@filter.project_group_ids)
    project_groups.each do |group|
      project_ids += group.projects.pluck(:id)
    end

    scope.in_project(project_ids.uniq).merge(GrdaWarehouse::Hud::Project.viewable_by(@filter.user))
  end

  private def filter_for_funders(scope)
    return scope if @filter.funder_ids.blank?

    project_ids = GrdaWarehouse::Hud::Funder.viewable_by(@filter.user).
      where(Funder: @filter.funder_ids).
      joins(:project).
      select(p_t[:id])
    scope.in_project(project_ids)
  end

  private def filter_for_data_sources(scope)
    return scope if @filter.data_source_ids.blank?

    scope.in_data_source(@filter.data_source_ids).joins(:data_source).merge(GrdaWarehouse::DataSource.viewable_by(@filter.user))
  end

  private def filter_for_organizations(scope)
    return scope if @filter.organization_ids.blank?

    scope.in_organization(@filter.organization_ids).merge(GrdaWarehouse::Hud::Organization.viewable_by(@filter.user))
  end

  private def filter_for_sub_population(scope)
    scope.public_send(@sub_population)
  end

  private def filter_for_prior_living_situation(scope)
    return scope if @filter.prior_living_situation_ids.blank?

    scope.where(housing_status_at_entry: @filter.prior_living_situation_ids)
  end

  private def filter_for_destination(scope)
    return scope if @filter.destination_ids.blank?

    scope.where(destination: @filter.destination_ids)
  end

  def date_range_words
    "#{start_date} - #{end_date}"
  end

  def report_scope_source
    GrdaWarehouse::ServiceHistoryEnrollment.entry
  end

  private def add_alternative(scope, alternative)
    if scope.present?
      scope.or(alternative)
    else
      alternative
    end
  end

  private def race_alternative(key)
    report_scope_source.joins(:client).where(c_t[key].eq(1))
  end

  def yn(boolean)
    boolean ? 'Yes' : 'No'
  end

  # An entry is an enrollment where the entry date is within the report range, and there are no entries in the
  # specified project types for the prior 24 months.
  def entries
    previous_period = report_scope_source.entry.
      open_between(start_date: @start_date - 24.months, end_date: @start_date - 1.day).
      with_service_between(start_date: @start_date - 24.months, end_date: @start_date - 1.day).
      in_project_type(@project_types)
    # To make this performant, we'll manipulate these a bit

    entries_current_period.where.not(period_exists_sql(previous_period))
  end

  def entries_current_period
    report_scope.entry_within_date_range(start_date: @start_date, end_date: @end_date).
      with_service_between(start_date: @start_date, end_date: @end_date)
  end

  # An exit is an enrollment where the exit date is within the report range, and there are no enrollments in the
  # specified project types that were open after the reporting period.
  def exits
    next_period = report_scope_source.entry.
      open_between(start_date: @end_date + 1.day, end_date: Date.current).
      with_service_between(start_date: @end_date + 1.day, end_date: Date.current).
      in_project_type(@project_types)

    exits_current_period.where.not(period_exists_sql(next_period))
  end

  def exits_current_period
    report_scope.exit_within_date_range(start_date: @start_date, end_date: @end_date).
      with_service_between(start_date: @start_date, end_date: @end_date)
  end

  def open_enrollments
    report_scope.open_between(start_date: @start_date, end_date: @end_date)
  end

  private def period_exists_sql(period)
    exists_sql(period, quoted_table_name: report_scope_source.quoted_table_name, alias_name: 'she_2', column_name: 'client_id')
  end
end
