###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Plain Ruby class to build race/ethnicity query conditions
# Centralizes the logic to avoid duplication between ClientRaceAndEthnicityMixin and filters
class RaceEthnicityQueryBuilder
  # Race field mappings from HUD utility
  RACE_FIELDS = (HudUtility2026.race_fields - [:RaceNone, :HispanicLatinaeo]).freeze
  MULTI_RACIAL_FIELDS = (HudUtility2026.race_fields - [:RaceNone, :HispanicLatinaeo]).freeze
  RACE_NONE_VALUES = [8, 9, 99].freeze
  MULTI_RACIAL_RANGE = (2..98)

  # Initialize with race selections
  # @param race_selections [Array<Hash>] Array of race selections in format:
  #   [{race: :Asian, hispanic: true}, {race: :White, hispanic: false}]
  def initialize(race_selections)
    @race_selections = Array(race_selections)
  end

  # Applies the query condition to an ActiveRecord scope
  # This is the main public API method that handles all race/ethnicity logic
  def apply_to_scope(scope, client_table_arel)
    return scope if @race_selections.empty?

    if @race_selections.size == 1
      # Single selection - handle directly
      apply_single_race_to_scope(scope, client_table_arel, @race_selections.first)
    else
      # Multiple selections - combine with OR/AND logic
      apply_multiple_races_to_scope(scope, client_table_arel)
    end
  end

  # Class methods for backward compatibility with existing scopes
  def self.multi_racial_sum_sql(client_table_arel, include_hispanic_latinaeo: false)
    fields = MULTI_RACIAL_FIELDS.dup
    fields << :HispanicLatinaeo if include_hispanic_latinaeo

    fields.map { |col| "COALESCE(#{client_table_arel[col].to_sql}, 0)" }.join(' + ')
  end

  def self.multi_racial_range
    MULTI_RACIAL_RANGE
  end

  private

  # Apply a single race condition to the scope
  def apply_single_race_to_scope(scope, client_table_arel, race_selection)
    race_key = race_selection[:race]
    hispanic_latinaeo = race_selection[:hispanic]

    case race_key
    when :MultiRacial, :multi_racial
      apply_multi_racial_to_scope(scope, client_table_arel, hispanic_latinaeo)
    when :RaceNone, :race_none
      values = RACE_NONE_VALUES.join(', ')
      scope.where("#{client_table_arel[:RaceNone].to_sql} IN (#{values})")
    else
      apply_standard_race_to_scope(scope, client_table_arel, race_key, hispanic_latinaeo)
    end
  end

  # Apply multiple race conditions combined with OR logic
  def apply_multiple_races_to_scope(scope, client_table_arel)
    # Build SQL OR conditions to avoid Arel reduce(:or) issues
    conditions = @race_selections.map do |race_selection|
      build_sql_condition_for_race(client_table_arel, race_selection)
    end
    scope.where(conditions.join(' OR '))
  end

  # Apply multi-racial condition
  def apply_multi_racial_to_scope(scope, client_table_arel, hispanic_latinaeo)
    sum_condition = self.class.multi_racial_sum_sql(client_table_arel, include_hispanic_latinaeo: false)
    hispanic_value = hispanic_latinaeo ? 1 : 0

    scope.where("(#{sum_condition}) BETWEEN ? AND ?", MULTI_RACIAL_RANGE.first, MULTI_RACIAL_RANGE.last).
      where("#{client_table_arel[:HispanicLatinaeo].to_sql} = ?", hispanic_value)
  end

  # Apply standard race condition (single race selection)
  def apply_standard_race_to_scope(scope, client_table_arel, race_key, hispanic_latinaeo)
    # Build SQL conditions with proper table references
    conditions = RACE_FIELDS.map do |field|
      value = field == race_key ? 1 : 0
      "#{client_table_arel[field].to_sql} = #{value}"
    end

    # Add Hispanic condition
    hispanic_value = hispanic_latinaeo ? 1 : 0
    conditions << "#{client_table_arel[:HispanicLatinaeo].to_sql} = #{hispanic_value}"

    scope.where(conditions.join(' AND '))
  end

  # Build SQL condition string for a single race (used in OR combinations)
  def build_sql_condition_for_race(client_table_arel, race_selection)
    race_key = race_selection[:race]
    hispanic_latinaeo = race_selection[:hispanic]

    case race_key
    when :MultiRacial, :multi_racial
      sum_condition = self.class.multi_racial_sum_sql(client_table_arel, include_hispanic_latinaeo: false)
      hispanic_condition = "#{client_table_arel[:HispanicLatinaeo].to_sql} = #{hispanic_latinaeo ? 1 : 0}"
      "(((#{sum_condition}) BETWEEN #{MULTI_RACIAL_RANGE.first} AND #{MULTI_RACIAL_RANGE.last}) AND #{hispanic_condition})"
    when :RaceNone, :race_none
      values = RACE_NONE_VALUES.join(', ')
      "#{client_table_arel[:RaceNone].to_sql} IN (#{values})"
    else
      # Standard race condition
      columns = RACE_FIELDS.map { |field| [field, 0] }.to_h
      columns[race_key] = 1
      columns[:HispanicLatinaeo] = 1 if hispanic_latinaeo

      conditions = columns.map { |field, value| "#{client_table_arel[field].to_sql} = #{value}" }.join(' AND ')
      "(#{conditions})"
    end
  end
end
