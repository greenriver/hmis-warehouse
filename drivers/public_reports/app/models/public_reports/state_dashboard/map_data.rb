###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# The `map` section of StateDashboard#chart_data: per-period,
# per-group homeless rates for each geography, snapped to the map color bands.
class PublicReports::StateDashboard::MapData
  include Filter::FilterScopes
  include ArelHelper

  GROUP_LABELS = [
    'All Homeless',
    'Youth and Young Adults (age 18-24)',
    'Adults in Adult Only Households (age 18+)',
    'Adults with Children',
    'Veterans',
  ].freeze

  # [max, label] per band, lowest first. Band 0 is drawn white; band n uses Setting#color(n - 1).
  PERCENT_BANDS = [
    [0, '0%'],
    [10.0, 'Any - 10%'],
    [15.0, '11% - 15%'],
    [20.0, '16% - 20%'],
    [25.0, '21% - 25%'],
    [100.0, '26%+'],
  ].freeze

  CENSUS_BANDS = [
    [0, 'None'],
    [3.0, 'Any - 3 per 10,000'],
    [6.0, '4 - 6 per 10,000'],
    [9.0, '7 - 9 per 10,000'],
    [12.0, '10 - 12 per 10,000'],
    [15.0, '13 - 15 per 10,000'],
    [18.0, '16 - 18 per 10,000'],
    [100.0, '19+ per 10,000'],
  ].freeze

  def initialize(report)
    @report = report
  end

  def to_h
    dates = @report.iteration_dates
    codes = geography.codes
    populations = codes.map { |code| overall_population_geography(dates.last.year, code) }
    group_scopes = (0...GROUP_LABELS.size).map { |i| group_scope(i) }

    values = []
    statewide_totals = []

    dates.each do |date|
      start_date = @report.beginning_iteration(date)
      end_date = @report.end_iteration(date)
      period_values = []
      period_totals = []

      group_scopes.each do |scope, service_scope|
        overall_homeless_population = homeless_population_overall(
          scope: scope,
          start_date: start_date,
          end_date: end_date,
          service_scope: service_scope,
          population_overall: populations.first,
        )
        period_totals << @report.published_total(overall_homeless_population)
        homeless_counts = homeless_counts_by_code(
          scope: scope,
          start_date: start_date,
          end_date: end_date,
          service_scope: service_scope,
          overall_homeless_population: overall_homeless_population,
        )

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

  # [scope, service_scope] for one group, index-aligned with GROUP_LABELS.
  private def group_scope(index)
    case index
    when 0
      [@report.homeless_scope, :current_scope]
    when 1
      # filter_for_age reads @filter
      @filter = @report.filter_object.deep_dup
      @filter.age_ranges = [:eighteen_to_twenty_four]
      [filter_for_age(@report.homeless_scope), GrdaWarehouse::ServiceHistoryService.aged(18..24)]
    when 2
      [@report.homeless_scope.adult_only_households, :current_scope]
    when 3
      [@report.homeless_scope.adults_with_children, :current_scope]
    when 4
      [@report.homeless_scope.veterans, :current_scope]
    end
  end

  private def overall_population_geography(year, code)
    return (500..2_000).to_a.sample if fake_counts?

    geography.population(year, code)
  end

  private def homeless_population_overall(scope:, start_date:, end_date:, service_scope:, population_overall:)
    if fake_counts?
      # This should change across quarter, but not geography
      max = [population_overall, 1].compact.max / 3
      @fake_overall_homeless_pop_per_quarter ||= {}
      @fake_overall_homeless_pop_per_quarter[start_date] ||= {}
      @fake_overall_homeless_pop_per_quarter[start_date][scope.to_s] ||= (0..max).to_a.sample
      @fake_overall_homeless_pop_per_quarter[start_date][scope.to_s]
    else
      scope.with_service_between(
        start_date: start_date,
        end_date: end_date,
        service_scope: service_scope,
      ).select(:client_id).distinct.count
    end
  end

  # code => distinct clients served in that geography, from one grouped query.
  private def homeless_counts_by_code(scope:, start_date:, end_date:, service_scope:, overall_homeless_population:)
    codes = geography.codes
    if fake_counts?
      max = [overall_homeless_population, 1].compact.max / 3
      return codes.to_h { |code| [code, (0..max).to_a.sample] }
    end

    enrolled_scope = scope.with_service_between(
      start_date: start_date,
      end_date: end_date,
      service_scope: service_scope,
    )
    # Place and county match case-insensitively, so their counts come back keyed by the lowercased name.
    grouped, case_insensitive = if geography.by_zip?
      [enrolled_scope.in_zip(zip_code: codes).group(pc_t[:Zip]), false]
    elsif geography.by_place?
      [enrolled_scope.in_place(place: codes).group(pc_t[:City].lower), true]
    elsif geography.by_county?
      # county_by_name downcases its argument in place, so it gets a copy of the memoized codes.
      [enrolled_scope.in_county(county: codes.dup).group(GrdaWarehouse::Shape::County.arel_table[:namelsad].lower), true]
    else
      [enrolled_scope.in_coc(coc_code: codes).group(pc_t[:CoCCode]), false]
    end
    counts = grouped.distinct.count(she_t[:client_id])
    codes.to_h { |code| [code, counts.fetch(case_insensitive ? code.downcase : code, 0)] }
  end

  # Census population (per 10,000) for the geography, or the statewide homeless population.
  private def tooltip_denominator(population_overall, overall_homeless_population)
    return population_overall.to_f / 100 if census_rate?

    overall_homeless_population.to_f
  end
end
