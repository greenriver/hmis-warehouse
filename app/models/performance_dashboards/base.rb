###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class PerformanceDashboards::Base
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
  def initialize(start_date:, end_date:, coc_codes: [], household_type: nil, hoh_only: false,
    age_ranges: [], genders: [], races: {}, ethnicities: [], veteran_statuses: [],  project_types: nil)
    @start_date = start_date
    @end_date = end_date
    @coc_codes = coc_codes
    @household_type = household_type
    @hoh_only = hoh_only
    @age_ranges = age_ranges
    @genders = genders
    @races = races
    @ethnicities = ethnicities
    @veteran_statuses = veteran_statuses
    @project_types = project_types || GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
  end

  attr_reader :start_date, :end_date

  def self.coc_codes
    GrdaWarehouse::Hud::ProjectCoc.distinct.pluck(:CoCCode)
  end

  def household_types
    {
      without_children: 'Households without children',
      with_children: 'Households with both adults and children',
      only_children: 'Households with only children',
    }.invert.freeze
  end

  def age_ranges
    {
      under_eighteen: '< 18',
      eighteen_to_twenty_four: '18 - 24',
      twenty_five_to_sixty_one: '25 - 61',
      over_sixty_one: '62+',
    }.invert.freeze
  end

  def self.comparison_patterns
    {
      prior_period: 'Prior Period',
      prior_year: 'Same period, prior year',
    }.invert.freeze
  end

  def self.valid_comparison_pattern?(pattern)
    comparison_patterns.values.include?(pattern&.to_sym)
  end

  # @return filtered scope
  def report_scope(all_project_types: false)
    # Report range
    scope = report_scope_source.
      open_between(start_date: @start_date, end_date: @end_date)

    # CoCs
    scope = scope.
      joins(:enrollment_coc_at_entry).
      where(ec_t[:CocCode].in(@coc_codes)) if @coc_codes.present?

    # Household Types
    case @household_type
    when :without_children
      scope = scope.where(other_clients_under_18: 0)
    when :with_children
      scope = scope.where(other_clients_under_18: 1)
    when :only_children
      scope = scope.where(children_only: true)
    end

    # HoH
    scope = scope.where(head_of_household: true) if @hoh_only

    # Age Ranges
    if @age_ranges.present?
      age_scope = nil
      age_scope = add_alternative(age_scope, report_scope_sourcewhere(she_t[:age].lt(18))) if @age_ranges.include?(:under_eighteen)

      if @age_ranges.include?(:eighteen_to_twenty_four)
        age_scope = add_alternative(
          age_scope,
          report_scope_source.where(
            she_t[:age].gteq(18).
            and(she_t[:age].lteq(24)),
          )
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
          report_scope_source.where(she_t[:age].gt(61),
        ))
      end

      scope = scope.merge(age_scope)
    end

    # Genders
    scope = scope.joins(:client).where(c_t[:Gender].in(@genders)) if @genders.present?

    # Races
    if @races.present?
      keys = @races.keys
      race_scope = nil

      race_scope = add_alternative(race_scope, race_alternative(:AmIndALNative)) if keys.include?('AmIndAKNative')
      race_scope = add_alternative(race_scope, race_alternative(:Asian)) if keys.include?('Asian')
      race_scope = add_alternative(race_scope, race_alternative(:BlackAfAmerican)) if keys.include?('BlackAfAmerican')
      race_scope = add_alternative(race_scope, race_alternative(:NativeHIOtherPacific)) if keys.include?('NativeHIOtherPacific')
      race_scope = add_alternative(race_scope, race_alternative(:White)) if keys.include?('White')
      race_scope = add_alternative(race_scope, race_alternative(:RaceNone)) if keys.include?('RaceNone')

      scope = scope.merge(race_scope)
    end

    # Ethnicities
    scope = scope.joins(:client).where(c_t[:Ethnicity].in(@ethnicities)) if @ethnicities.present?

    # Veteran Statuses
    scope = scope.joins(:client).where(c_t[:VeteranStatus].in(@veteran_statuses)) if @veteran_statuses.present?

    # Project Types
    scope = scope.where(project_type: @project_types) unless all_project_types

    scope
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
end