###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# The `who` section of StateDashboard#chart_data: donuts, the race
# chart and the demographic breakdowns, one entry per iteration_dates period.
class PublicReports::StateDashboard::WhoData
  def initialize(report)
    @report = report
  end

  def to_h
    periods = @report.period_labels
    {
      periods: periods,
      currentIndex: periods.size - 1,
      donuts: {
        'all-people' => all_people_donut,
        'veterans' => veterans_donut,
        'household-type' => household_type_donut,
      },
      race: race_chart,
      raceTitleCategories: ['Homeless Population', 'Overall Population'],
      breakdown: breakdowns.rows,
      breakdownGroupings: breakdowns.groupings,
    }
  end

  private def breakdowns
    @breakdowns ||= PublicReports::StateDashboard::Breakdowns.new(@report)
  end

  private def settings
    @report.settings
  end

  # counts_by_period: one raw-count array per iteration_dates entry, in labels order.
  private def donut(title:, unit:, labels:, colors:, counts_by_period:, threshold_key:)
    values = []
    totals = []
    counts_by_period.each do |counts|
      total = counts.sum
      totals << @report.published_total(total)
      values << @report.enforce_min_threshold(counts.dup, threshold_key)
    end
    {
      title: title,
      unit: unit,
      labels: labels,
      colors: colors,
      values: values,
      totals: totals,
    }
  end

  private def period_scope(date)
    @report.homeless_scope.with_service_between(
      start_date: @report.beginning_iteration(date),
      end_date: @report.end_iteration(date),
    )
  end

  private def location_counts(scope)
    [
      scope.homeless_sheltered.select(:client_id).distinct.count,
      scope.homeless_unsheltered.select(:client_id).distinct.count,
    ]
  end

  private def all_people_donut
    donut(
      title: 'All People',
      unit: 'People',
      labels: ['Sheltered', 'Unsheltered'],
      colors: [settings.color(0, :location_type), settings.color(1, :location_type)],
      counts_by_period: @report.iteration_dates.map { |date| location_counts(period_scope(date)) },
      threshold_key: 'location',
    )
  end

  private def veterans_donut
    donut(
      title: 'Veterans',
      unit: 'Veterans',
      labels: ['Sheltered', 'Unsheltered'],
      colors: [settings.color(0, :location_type), settings.color(1, :location_type)],
      counts_by_period: @report.iteration_dates.map { |date| location_counts(period_scope(date).veteran) },
      threshold_key: 'location',
    )
  end

  private def household_type_donut
    counts_by_period = @report.iteration_dates.map do |date|
      start_date = @report.beginning_iteration(date)
      end_date = @report.end_iteration(date)
      [
        breakdowns.adult_only_household_ids(start_date, end_date).values.uniq.count,
        breakdowns.adult_and_child_household_ids(start_date, end_date).values.uniq.count,
        breakdowns.child_only_household_ids(start_date, end_date).values.uniq.count,
      ]
    end
    donut(
      title: 'Household Type',
      unit: 'Households',
      labels: ['Adult Only', 'Adults with Children', 'Children-Only Households'],
      colors: (0..2).map { |i| settings.color(i, :household_composition) },
      counts_by_period: counts_by_period,
      threshold_key: 'household_type',
    )
  end

  private def race_chart
    # Manually do HUD race lookup to avoid a bunch of unnecessary mapping and lookups
    # NOTE: HispanicLatinaeo and MidEastNAfrican are not included in the census data, so we're ignoring them
    races = ::HudHelper.util.races(multi_racial: true).except('HispanicLatinaeo', 'MidEastNAfrican')
    client_cache = GrdaWarehouse::Hud::Client.new

    labels = nil
    colors = nil
    overall = nil
    homeless_rows = []
    totals = []

    dates = @report.iteration_dates
    dates.each_with_index do |date, index|
      client_ids = Set.new
      data = {}
      census_data = {}
      full_pop = (@report.geography.population_by_race(year: date.year) || 0).to_f
      races.each do |race_code, label|
        data[label] ||= Set.new
        race_pop = @report.geography.population_by_race(race_code: race_code, year: date.year) || 0
        census_data[label] = full_pop.positive? ? (race_pop.to_f / full_pop) * 100.0 : 0.0
      end

      period_scope(date).joins(:client).preload(:client).
        order(first_date_in_program: :desc). # Use the newest start
        find_each do |enrollment|
          client = enrollment.client
          race_code = client_cache.race_string(destination_id: client.id)
          race_label = races[race_code]
          data[race_label] << client.id if race_label && ! client_ids.include?(client.id)
          client_ids << client.id
        end
      total_count = data.map { |_, ids| ids.count }.sum
      data = @report.enforce_min_threshold(data, 'race')

      labels ||= data.keys.map { |race| race == 'None' ? 'Other or Unknown' : race }
      colors ||= labels.each_with_index.to_h { |label, i| [label, settings.color(i, :race)] }

      homeless_rows << data.map do |_race, ids|
        total_count.positive? ? ((ids.count * 100.0) / total_count).round(1) : 0.0
      end
      totals << @report.published_total(total_count)

      overall = data.keys.map { |race| race == 'None' ? nil : census_data[race]&.round(1) } if index == dates.size - 1
    end

    {
      labels: labels,
      colors: colors,
      overall: overall,
      homeless: homeless_rows,
      totals: totals,
    }
  end
end
