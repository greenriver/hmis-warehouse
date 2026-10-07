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

        period_values << codes.map do |code|
          population_overall = overall_population_geography(date.year, code)
          next nil if census_rate? && population_overall.to_i.zero?

          homeless_count = count_homeless_population(
            scope: scope,
            start_date: start_date,
            end_date: end_date,
            service_scope: service_scope,
            overall_homeless_population: overall_homeless_population,
            code: code,
          )
          homeless_count = @report.enforce_min_threshold(homeless_count, 'min_threshold') unless census_rate?

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
      bands: colors.map { |color, info| { max: info[:high], color: color, label: info[:description] } },
      notReportingColor: settings.theme[:not_reporting],
      unit: census_rate? ? 'Rate per 10,000 population' : 'Percentage of homeless population',
      map_type: settings.map_type,
    }
  end

  def colors
    @colors ||= {}.tap do |m_colors|
      colors = ['#FFFFFF']
      8.times do |i|
        colors << settings.color(i)
      end
      if census_rate?
        m_colors[colors[0]] = { description: 'None', range: (0..0), low: 0, high: 0 }
        m_colors[colors[1]] = { description: 'Any - 3 per 10,000', range: (0.000001..3.0), low: 0.000001, high: 3.0 }
        m_colors[colors[2]] = { description: '4 - 6 per 10,000', range: (4.000001..6.0), low: 4.000001, high: 6.0 }
        m_colors[colors[3]] = { description: '7 - 9 per 10,000', range: (7.000001..9.0), low: 7.000001, high: 9.0 }
        m_colors[colors[4]] = { description: '10 - 12 per 10,000', range: (10.000001..12.0), low: 10.000001, high: 12.0 }
        m_colors[colors[5]] = { description: '13 - 15 per 10,000', range: (13.000001..15.0), low: 13.000001, high: 15.0 }
        m_colors[colors[6]] = { description: '16 - 18 per 10,000', range: (16.000001..18.0), low: 16.000001, high: 18.0 }
        m_colors[colors[7]] = { description: '19+ per 10,000', range: (18.000001..100.0), low: 18.000001, high: 100.0 }
      else
        m_colors[colors[0]] = { description: '0%', range: (0..0), low: 0, high: 0 }
        m_colors[colors[1]] = { description: 'Any - 10%', range: (0.000001..10.0), low: 0.000001, high: 10.0 }
        m_colors[colors[2]] = { description: '11% - 15%', range: (10.000001..15.0), low: 10.000001, high: 15.0 }
        m_colors[colors[3]] = { description: '16% - 20%', range: (15.000001..20.0), low: 15.000001, high: 20.0 }
        m_colors[colors[4]] = { description: '21% - 25%', range: (20.000001..25.0), low: 20.000001, high: 25.0 }
        m_colors[colors[5]] = { description: '26%+', range: (25.000001..100.0), low: 25.000001, high: 100.0 }
      end
    end
  end

  # Snaps a rate to the upper bound of the color band it falls into.
  def snap_rate(rate)
    bucket = colors.values.detect { |b| rate <= b[:high] }
    (bucket || colors.values.last)[:high]
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

  private def fake_counts?
    !Rails.env.production?
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

  private def count_homeless_population(scope:, start_date:, end_date:, service_scope:, overall_homeless_population:, code:)
    if fake_counts?
      max = [overall_homeless_population, 1].compact.max / 3
      (0..max).to_a.sample
    else
      enrolled_scope = scope.with_service_between(
        start_date: start_date,
        end_date: end_date,
        service_scope: service_scope,
      )
      geography_scope = if geography.by_zip?
        enrolled_scope.in_zip(zip_code: code)
      elsif geography.by_place?
        enrolled_scope.in_place(place: code)
      elsif geography.by_county?
        enrolled_scope.in_county(county: code)
      else
        enrolled_scope.in_coc(coc_code: code)
      end
      geography_scope.select(:client_id).distinct.count
    end
  end

  # Census population (per 10,000) for the geography, or the statewide homeless population.
  private def tooltip_denominator(population_overall, overall_homeless_population)
    return population_overall.to_f / 100 if census_rate?

    overall_homeless_population.to_f
  end
end
