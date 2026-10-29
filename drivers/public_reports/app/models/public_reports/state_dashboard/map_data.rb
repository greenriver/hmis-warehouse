###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# The `map` section of StateDashboard#chart_data: per-period,
# per-group homeless rates for each geography, snapped to the map color bands.
class PublicReports::StateDashboard::MapData
  include ArelHelper

  GROUP_LABELS = [
    'All Homeless',
    'Youth and Young Adults (age 18-24)',
    'Adults in Adult Only Households (age 18+)',
    'Adults with Children',
    'Veterans',
  ].freeze

  # [max, label] per band, lowest first; a band holds rates above the previous max up to its own.
  # Band 0 is drawn white; band n uses Setting#color(n - 1).
  PERCENT_BANDS = [
    [0, '0%'],
    [10.0, 'Over 0% to 10%'],
    [15.0, 'Over 10% to 15%'],
    [20.0, 'Over 15% to 20%'],
    [25.0, 'Over 20% to 25%'],
    [100.0, 'Over 25%'],
  ].freeze

  CENSUS_BANDS = [
    [0, 'None'],
    [3.0, 'Over 0 to 3 per 10,000'],
    [6.0, 'Over 3 to 6 per 10,000'],
    [9.0, 'Over 6 to 9 per 10,000'],
    [12.0, 'Over 9 to 12 per 10,000'],
    [15.0, 'Over 12 to 15 per 10,000'],
    [18.0, 'Over 15 to 18 per 10,000'],
    [100.0, 'Over 18 per 10,000'],
  ].freeze

  def initialize(report)
    @report = report
  end

  def to_h
    dates = @report.iteration_dates
    codes = geography.codes
    populations = codes.map { |code| overall_population_geography(dates.last.year, code) }

    values = []
    statewide_totals = []

    dates.each do |date|
      start_date = @report.beginning_iteration(date)
      end_date = @report.end_iteration(date)
      overall_counts = group_overall_counts(start_date, end_date, populations.first)
      code_counts = group_counts_by_code(start_date, end_date, overall_counts)
      period_values = []
      period_totals = []

      overall_counts.zip(code_counts).each do |overall_homeless_population, homeless_counts|
        period_total = @report.published_total(overall_homeless_population)
        period_totals << period_total
        # With the group total hidden, any banded town would show where its few clients were served.
        if period_total.nil?
          period_values << Array.new(codes.size)
          next
        end

        # Every period divides by the published population so the rate matches the population shown beside it.
        period_values << codes.each_with_index.map do |code, code_index|
          population_overall = populations[code_index]
          next nil if census_rate? && population_overall.to_i.zero?

          homeless_count = @report.enforce_min_threshold(homeless_counts.fetch(code), 'min_threshold')

          denominator = tooltip_denominator(population_overall, overall_homeless_population)
          rate = denominator&.positive? ? (homeless_count / denominator.to_f) * 100.0 : 0.0
          snap_rate(rate.round(1))
        end
      end

      values << period_values
      statewide_totals << period_totals
    end

    {
      towns: codes.map { |code| geography.display_name(code) },
      periods: @report.period_labels,
      groups: GROUP_LABELS,
      values: values,
      populations: populations,
      statewideTotals: statewide_totals,
      bands: bands,
      notReportingColor: settings.theme[:not_reporting],
      unit: census_rate? ? 'Rate per 10,000 population' : 'Percentage of homeless population',
      map_type: settings.map_type,
    }
  end

  def bands
    @bands ||= (census_rate? ? CENSUS_BANDS : PERCENT_BANDS).each_with_index.map do |(max, label), index|
      { max: max, color: index.zero? ? '#FFFFFF' : settings.color(index - 1), label: label }
    end
  end

  # Snaps a rate to the upper bound of the color band it falls into.
  def snap_rate(rate)
    (bands.detect { |band| rate <= band[:max] } || bands.last)[:max]
  end

  private def settings
    @report.settings
  end

  private def geography
    @report.geography
  end

  private def census_rate?
    settings.map_overall_geography_census?
  end

  # Development databases rarely have shapes or census data, so sample counts there. Every
  # other environment, test and staging included, publishes real counts.
  private def fake_counts?
    Rails.env.development?
  end

  # Index-aligned with GROUP_LABELS: the StateDashboard#period_count_conditions key each group
  # counts under, or nil for the youth group, which counts only 18-24 services.
  GROUP_CONDITION_KEYS = [:all, nil, :adult_only_households, :adults_with_children, :veterans].freeze

  # Age is the age recorded on each service, so a client counts in the periods they were 18-24.
  private def youth_enrolled_scope(start_date, end_date)
    @report.homeless_scope.with_service_between(
      start_date: start_date,
      end_date: end_date,
      service_scope: GrdaWarehouse::ServiceHistoryService.aged(18..24),
    )
  end

  private def overall_population_geography(year, code)
    return (500..2_000).to_a.sample if fake_counts?

    geography.population(year, code)
  end

  # Distinct clients served in the period, one per group.
  private def group_overall_counts(start_date, end_date, population_overall)
    return GROUP_LABELS.each_index.map { |index| fake_overall_count(start_date, index, population_overall) } if fake_counts?

    shared = @report.period_client_counts(start_date, end_date)
    GROUP_CONDITION_KEYS.map do |key|
      key ? shared.fetch(key) : youth_enrolled_scope(start_date, end_date).select(:client_id).distinct.count
    end
  end

  private def fake_overall_count(start_date, index, population_overall)
    # This should change across quarter, but not geography
    max = [population_overall, 1].compact.max / 3
    @fake_overall_homeless_pop_per_quarter ||= {}
    @fake_overall_homeless_pop_per_quarter[[start_date, index]] ||= (0..max).to_a.sample
  end

  # One code => distinct clients hash per group. The groups that share period_count_conditions
  # are counted in one grouped query, the youth group in another.
  private def group_counts_by_code(start_date, end_date, overall_counts)
    codes = geography.codes
    if fake_counts?
      return overall_counts.map do |overall|
        max = [overall, 1].compact.max / 3
        codes.to_h { |code| [code, (0..max).to_a.sample] }
      end
    end

    shared_keys = GROUP_CONDITION_KEYS.compact
    conditions = @report.period_count_conditions.values_at(*shared_keys)
    scope = @report.homeless_scope.with_service_between(start_date: start_date, end_date: end_date).left_joins(:client)
    grouped, code_column, case_insensitive = in_geography(scope)
    shared_rows = grouped.group(code_column).pluck(code_column, *@report.distinct_client_counts(conditions))
    shared_counts = shared_keys.each_with_index.to_h do |key, index|
      [key, shared_rows.to_h { |code, *counts| [code, counts[index]] }]
    end

    youth_grouped, youth_code_column, = in_geography(youth_enrolled_scope(start_date, end_date))
    youth_counts = youth_grouped.group(youth_code_column).distinct.count(she_t[:client_id])

    GROUP_CONDITION_KEYS.map do |key|
      counts = key ? shared_counts.fetch(key) : youth_counts
      codes.to_h { |code| [code, counts.fetch(case_insensitive ? code.downcase : code, 0)] }
    end
  end

  # [scope limited to the map's codes, code column to group by, whether codes come back lowercased].
  # Place and county match case-insensitively, so their counts come back keyed by the lowercased name.
  private def in_geography(scope)
    codes = geography.codes
    if geography.by_zip?
      [scope.in_zip(zip_code: codes), pc_t[:Zip], false]
    elsif geography.by_place?
      [scope.in_place(place: codes), pc_t[:City].lower, true]
    elsif geography.by_county?
      # county_by_name downcases its argument in place, so it gets a copy of the memoized codes.
      [scope.in_county(county: codes.dup), GrdaWarehouse::Shape::County.arel_table[:namelsad].lower, true]
    else
      [scope.in_coc(coc_code: codes), pc_t[:CoCCode], false]
    end
  end

  # Census population (per 10,000) for the geography, or the statewide homeless population.
  private def tooltip_denominator(population_overall, overall_homeless_population)
    return population_overall.to_f / 100 if census_rate?

    overall_homeless_population.to_f
  end
end
