###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'memery'
# Demographic breakdown rows for the who section, by household type, gender
# and race, plus the household classification they and the household-type
# donut share.
class PublicReports::StateLevelHomelessness::Breakdowns
  include ArelHelper
  include Memery

  def initialize(report)
    @report = report
  end

  # rowId => { totals:, chronic:, sheltered:, unsheltered: }, one array entry per iteration_dates period.
  def rows
    dates = @report.iteration_dates
    num_periods = dates.size
    rows = {}

    dates.each_with_index do |date, date_index|
      start_date = @report.beginning_iteration(date)
      end_date = @report.end_iteration(date)
      shs_scope = GrdaWarehouse::ServiceHistoryService.where(date: start_date..end_date)
      base_scope = @report.homeless_scope.with_service_between(
        start_date: start_date,
        end_date: end_date,
        service_scope: shs_scope,
      ).joins(:client)

      household_type_setups.each do |section_index, section|
        quarter_setup = section[:rows].transform_values { |client_scope| client_scope.merge(shs_scope) }
        household_ids = case section_index
        when 0 then adult_only_household_ids(start_date, end_date).keys
        when 1 then adult_and_child_household_ids(start_date, end_date).keys
        when 2 then child_only_household_ids(start_date, end_date).keys
        end
        section_scope = base_scope.where(household_id: household_ids)
        # NOTE: for adults with children we sum all categories together
        compute_rows(
          rows: rows,
          grouping: 'household_type',
          section_index: section_index,
          setup: quarter_setup,
          scope: section_scope,
          date_index: date_index,
          num_periods: num_periods,
          combine_rows: section_index == 1,
        )
      end

      gender_setups.each do |section_index, section|
        compute_rows(
          rows: rows,
          grouping: 'gender',
          section_index: section_index,
          setup: section[:rows],
          scope: base_scope,
          date_index: date_index,
          num_periods: num_periods,
          combine_rows: false,
        )
      end

      race_setups.each do |section_index, section|
        compute_rows(
          rows: rows,
          grouping: 'race',
          section_index: section_index,
          setup: section[:rows],
          scope: base_scope,
          date_index: date_index,
          num_periods: num_periods,
          combine_rows: false,
        )
      end
    end

    rows.each_value { |row| row[:sheltered] = nil if row[:sheltered].all?(&:nil?) }
    rows
  end

  def groupings
    {
      household_type: {
        label: 'Household Type',
        sections: household_type_setups.values.map { |section| { heading: section[:heading], rows: section[:rows].keys } },
      },
      gender: {
        label: 'Gender',
        sections: gender_setups.values.map { |section| { heading: section[:heading], rows: section[:rows].keys } },
      },
      race: {
        label: 'Race',
        sections: race_setups.values.map { |section| { heading: section[:heading], rows: section[:rows].keys } },
      },
    }
  end

  # household_id => head of household client_id, for each household type.
  def adult_and_child_household_ids(start_date, end_date)
    adult_and_child_households = {}
    households(start_date, end_date).each do |hh_id, household|
      child_present = household[:ages].any? { |age| age < 18 }
      adult_present = household[:ages].any? { |age| age >= 18 }
      adult_and_child_households[hh_id] = household[:hoh_client_id] if child_present && adult_present
    end
    adult_and_child_households
  end
  memoize :adult_and_child_household_ids

  def child_only_household_ids(start_date, end_date)
    child_only_households = {}
    households(start_date, end_date).each do |hh_id, household|
      child_present = household[:ages].any? { |age| age < 18 }
      adult_present = household[:ages].any? { |age| age >= 18 }
      child_only_households[hh_id] = household[:hoh_client_id] if child_present && ! adult_present
    end
    child_only_households
  end
  memoize :child_only_household_ids

  def adult_only_household_ids(start_date, end_date)
    adult_only_household_ids = {}
    households(start_date, end_date).each do |hh_id, household|
      child_present = household[:ages].any? { |age| age < 18 }
      # Include clients of unknown age
      adult_only_household_ids[hh_id] = household[:hoh_client_id] unless child_present
    end
    adult_only_household_ids
  end
  memoize :adult_only_household_ids

  private def compute_rows(rows:, grouping:, section_index:, setup:, scope:, date_index:, num_periods:, combine_rows:)
    chronic_scope = scope.joins(enrollment: :ch_enrollment).
      merge(GrdaWarehouse::ChEnrollment.chronically_homeless)

    combined_chronic_count = nil
    combined_total_count = nil
    if combine_rows
      combined_chronic_count = 0
      combined_total_count = 0
      setup.each_value do |client_scope|
        combined_chronic_count += chronic_scope.where(client_id: scope.merge(client_scope).distinct.pluck(:client_id)).count
        combined_total_count += scope.merge(client_scope).distinct.select(:client_id).count
      end
    end

    setup.keys.each_with_index do |title, row_index|
      client_scope = setup[title]
      row_id = "#{grouping}__#{section_index}__#{row_index}"
      rows[row_id] ||= {
        totals: Array.new(num_periods),
        chronic: Array.new(num_periods),
        sheltered: Array.new(num_periods),
        unsheltered: Array.new(num_periods),
      }

      chronic_count = chronic_scope.where(client_id: scope.merge(client_scope).distinct.pluck(:client_id)).count
      total_count = scope.merge(client_scope).distinct.select(:client_id).count
      sheltered_count = scope.homeless_sheltered.merge(client_scope).select(:client_id).distinct.count
      unsheltered_count = scope.homeless_unsheltered.merge(client_scope).select(:client_id).distinct.count

      chronic_count = combined_chronic_count if combine_rows

      row_total = @report.published_total(total_count)
      rows[row_id][:totals][date_index] = row_total
      rows[row_id][:chronic][date_index] = @report.enforce_min_threshold([chronic_count, combine_rows ? combined_total_count : total_count], 'chronic_percents')

      # A suppressed total would be recoverable as sheltered + unsheltered.
      if row_total.nil? || sheltered_count < PublicReports::StateLevelHomelessness::MIN_THRESHOLD || unsheltered_count < PublicReports::StateLevelHomelessness::MIN_THRESHOLD
        rows[row_id][:sheltered][date_index] = nil
        rows[row_id][:unsheltered][date_index] = nil
      else
        rows[row_id][:sheltered][date_index] = sheltered_count
        rows[row_id][:unsheltered][date_index] = unsheltered_count
      end
    end
  end

  private def household_type_setups
    {
      0 => {
        heading: 'Persons in Households Without Children',
        rows: {
          'Persons Age 18 to 24' => GrdaWarehouse::ServiceHistoryEnrollment.joins(:service_history_services).merge(GrdaWarehouse::ServiceHistoryService.aged(18..24)),
          'Persons over age 24' => GrdaWarehouse::ServiceHistoryEnrollment.joins(:service_history_services).merge(GrdaWarehouse::ServiceHistoryService.aged(24..105)),
          'Persons of unknown age' => GrdaWarehouse::ServiceHistoryEnrollment.joins(:service_history_services).merge(GrdaWarehouse::ServiceHistoryService.unknown_age),
        },
      },
      1 => {
        heading: 'Persons in households with at least one child and one adult',
        rows: {
          'Children under 18' => GrdaWarehouse::ServiceHistoryEnrollment.joins(:service_history_services).merge(GrdaWarehouse::ServiceHistoryService.aged(0..17)),
          'Persons Age 18 to 24' => GrdaWarehouse::ServiceHistoryEnrollment.joins(:service_history_services).merge(GrdaWarehouse::ServiceHistoryService.aged(18..24)),
          'Persons over age 24' => GrdaWarehouse::ServiceHistoryEnrollment.joins(:service_history_services).merge(GrdaWarehouse::ServiceHistoryService.aged(24..105)),
          'Persons of unknown age' => GrdaWarehouse::ServiceHistoryEnrollment.joins(:service_history_services).merge(GrdaWarehouse::ServiceHistoryService.unknown_age),
        },
      },
      2 => {
        heading: 'Persons in Child-Only Households',
        rows: {
          'Children under 18' => GrdaWarehouse::ServiceHistoryEnrollment.joins(:service_history_services).merge(GrdaWarehouse::ServiceHistoryService.aged(0..17)),
        },
      },
    }
  end

  private def gender_setups
    # NOTE: only minorly updating this for now.  Since these are published publicly, we'll wait until we
    # have better direction on the scope of what's desired
    {
      0 => {
        heading: nil,
        rows: {
          'Woman' => GrdaWarehouse::Hud::Client.gender_woman,
          'Man' => GrdaWarehouse::Hud::Client.gender_man,
          'Transgender' => GrdaWarehouse::Hud::Client.gender_transgender,
          'Non-Binary' => GrdaWarehouse::Hud::Client.gender_non_binary,
          'Other or Unknown' => GrdaWarehouse::Hud::Client.gender_unknown.or(GrdaWarehouse::Hud::Client.questioning),
        },
      },
    }
  end

  private def race_setups
    # TODO: DEPRECATED_FY2024 need to revisit this since race and ethnicity have been combined.
    # We need to figure out how we'll represent that given the census data has a different shape.
    {
      0 => {
        heading: nil,
        rows: {
          'American Indian or Alaska Native' => GrdaWarehouse::Hud::Client.with_races(['AmIndAKNative']),
          'Asian' => GrdaWarehouse::Hud::Client.with_races(['Asian']),
          'Black or African American' => GrdaWarehouse::Hud::Client.with_races(['BlackAfAmerican']),
          'Native Hawaiian or Pacific Islander' => GrdaWarehouse::Hud::Client.with_races(['NativeHIPacific']),
          # NOTE: these two are not included in the census data, so we're ignoring them
          # 'Hispanic/Latina/e/o' => GrdaWarehouse::Hud::Client.with_races(['HispanicLatinaeo']),
          # 'Middle Eastern or North African' => GrdaWarehouse::Hud::Client.with_races(['MidEastNAfrican']),
          'White' => GrdaWarehouse::Hud::Client.with_races(['White']),
          'Other or Unknown' => GrdaWarehouse::Hud::Client.with_race_none,
        },
      },
    }
  end

  # household_id => { ages:, hoh_client_id: } for households served in the period.
  private def households(start_date, end_date)
    households = {}
    counted_ids = Set.new
    shs_scope = GrdaWarehouse::ServiceHistoryService.where(date: start_date..end_date)
    @report.homeless_scope.with_service_between(
      start_date: start_date,
      end_date: end_date,
      service_scope: shs_scope,
    ).
      joins(:service_history_services).
      merge(shs_scope).
      order(shs_t[:date].asc).
      pluck(cl(she_t[:household_id], she_t[:enrollment_group_id]), shs_t[:age], shs_t[:client_id], she_t[:head_of_household]).
      each do |hh_id, age, client_id, hoh|
        next if age.blank? || age.negative?

        key = [hh_id, client_id]
        households[hh_id] ||= { ages: [], hoh_client_id: nil }
        households[hh_id][:ages] << age unless counted_ids.include?(key)
        households[hh_id][:hoh_client_id] = client_id if hoh
        counted_ids << key
      end
    households
  end
  memoize :households
end
