###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
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
    @project_types = filter.project_types || GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
    @comparison_pattern = filter.comparison_pattern
    @sub_population = valid_sub_population(filter.sub_population)
  end

  attr_reader :start_date, :end_date, :coc_codes, :project_types, :filter
  attr_accessor :comparison_pattern, :project_type_codes

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
      without_children: 'Households without children',
      with_children: 'Households with both adults and children',
      only_children: 'Households with only children',
    }.invert.freeze
  end

  def household_type(type)
    household_types.invert[type] || 'Unknown'
  end

  def age_ranges
    {
      under_eighteen: '< 18',
      eighteen_to_twenty_four: '18 - 24',
      twenty_five_to_sixty_one: '25 - 61',
      over_sixty_one: '62+',
    }.invert.freeze
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

  def chosen_household_type
    household_type(@household_type.to_sym)
  end

  def chosen_sub_population
    Reporting::MonthlyReports::Base.available_types[@sub_population]&.new&.sub_population_title
  end

  def chosen_races
    @races.keys.map do |race|
      HUD.race(race)
    end
  end

  def chosen_ethnicities
    @ethnicities.map do |ethnicity|
      HUD.ethnicity(ethnicity)
    end
  end

  def self.comparison_patterns
    {
      prior_year: 'Same period, prior year',
      prior_period: 'Prior Period',
      no_comparison_period: 'No comparison period',
    }.invert.freeze
  end

  def self.valid_comparison_pattern?(pattern)
    comparison_patterns.values.include?(pattern&.to_sym)
  end

  def self.sub_populations
    Reporting::MonthlyReports::Base.available_types.map { |k, klass| [klass.new.sub_population_title, k] }.to_h
  end

  def valid_sub_population(population)
    self.class.sub_populations.values.detect { |m| m == population&.to_sym } || :all_clients
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
    scope
  end

  private def filter_for_range(scope)
    scope.open_between(start_date: @start_date, end_date: @end_date)
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
      scope.where(other_clients_under_18: 0)
    when :with_children
      scope.where(other_clients_under_18: 1)
    when :only_children
      scope.where(children_only: true)
    end
  end

  private def filter_for_head_of_household(scope)
    return scope unless @hoh_only

    scope.where(she_t[:head_of_household].eq(true))
  end

  private def filter_for_age(scope)
    return scope unless @age_ranges.present?

    age_scope = nil
    if @age_ranges.include?(:under_eighteen)
      age_scope = add_alternative(
        age_scope,
        report_scope_source.where(she_t[:age].lt(18)),
      )
    end

    if @age_ranges.include?(:eighteen_to_twenty_four)
      age_scope = add_alternative(
        age_scope,
        report_scope_source.where(
          she_t[:age].gteq(18).
          and(she_t[:age].lteq(24)),
        ),
      )
    end

    if @age_ranges.include?(:twenty_five_to_sixty_one)
      age_scope = add_alternative(
        age_scope,
        report_scope_source.where(
          she_t[:age].gteq(25).
          and(she_t[:age].lteq(61)),
        ),
      )
    end

    if @age_ranges.include?(:over_sixty_one)
      age_scope = add_alternative(
        age_scope,
        report_scope_source.where(she_t[:age].gt(61)),
      )
    end

    scope.merge(age_scope)
  end

  private def filter_for_gender(scope)
    return scope unless @genders.present?

    scope.joins(:client).where(c_t[:Gender].in(@genders))
  end

  private def filter_for_race(scope)
    return scope unless @races.present?

    keys = @races.keys
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

    scope.where(project_type: @project_types)
  end

  private def filter_for_sub_population(scope)
    scope.public_send(@sub_population)
  end

  def date_range_words
    "#{start_date} - #{end_date}"
  end

  def report_scope_source
    GrdaWarehouse::ServiceHistoryEnrollment
  end

  private def add_alternative(scope, alternative)
    if scope.present?
      scope.or(alternative)
    else
      alternative
    end
  end

  private def race_alternative(key)
    report_scope_source.joins(:client).where(c_t[key].in(@races[key.to_s]))
  end

  def yn(boolean)
    boolean ? 'Yes' : 'No'
  end

  # An entry is an enrollment where the entry date is within the report range, and there are no entries in the
  # specified project types for the prior 24 months.
  def entries
    previous_period = report_scope_source.
      open_between(start_date: @start_date - 24.months, end_date: @start_date - 1.day).
      where(project_type: @project_types)

    entries_current_period.where.not(client_id: previous_period.select(:client_id))
  end

  def entries_current_period
    report_scope.entry_within_date_range(start_date: @start_date, end_date: @end_date)
  end

  # An exit is an enrollment where the exit date is within the report range, and there are no enrollments in the
  # specified project types that were open after the reporting period.
  def exits
    next_period = report_scope_source.
      open_between(start_date: @end_date + 1.day, end_date: Date.current).
      where(project_type: @project_types)

    exits_current_period.where.not(client_id: next_period.select(:client_id))
  end

  def exits_current_period
    report_scope.exit_within_date_range(start_date: @start_date, end_date: @end_date)
  end

  def open_enrollments
    report_scope.open_between(start_date: @start_date, end_date: @end_date)
  end
end
