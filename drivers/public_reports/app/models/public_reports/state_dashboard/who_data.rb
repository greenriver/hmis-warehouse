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
  private def donut(title:, unit:, labels:, colors:, counts_by_period:, threshold_key:, totals_by_period: counts_by_period.map(&:sum))
    values = []
    totals = []
    counts_by_period.zip(totals_by_period).each do |counts, total|
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

  private def period_client_counts
    @report.iteration_dates.map do |date|
      @report.period_client_counts(@report.beginning_iteration(date), @report.end_iteration(date))
    end
  end

  private def all_people_donut
    donut(
      title: 'All People',
      unit: 'People',
      labels: ['Sheltered', 'Unsheltered'],
      colors: [settings.color(0, :location_type), settings.color(1, :location_type)],
      counts_by_period: period_client_counts.map { |counts| counts.values_at(:sheltered, :unsheltered) },
      totals_by_period: period_client_counts.map { |counts| counts[:all] },
      threshold_key: 'location',
    )
  end

  private def veterans_donut
    donut(
      title: 'Veterans',
      unit: 'Veterans',
      labels: ['Sheltered', 'Unsheltered'],
      colors: [settings.color(0, :location_type), settings.color(1, :location_type)],
      counts_by_period: period_client_counts.map { |counts| counts.values_at(:veterans_sheltered, :veterans_unsheltered) },
      totals_by_period: period_client_counts.map { |counts| counts[:veterans] },
      threshold_key: 'location',
    )
  end

  private def household_type_donut
    counts_by_period = @report.iteration_dates.map do |date|
      breakdowns.household_type_counts(@report.beginning_iteration(date), @report.end_iteration(date)).
        values_at(*PublicReports::StateDashboard::Breakdowns::HOUSEHOLD_TYPES)
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
    # NOTE: the census has no HispanicLatinaeo or MidEastNAfrican category, so a client whose only
    # race is one of those counts in the 'None' (Other or Unknown) bucket, which has no census share.
    races = ::HudHelper.util.races(multi_racial: true).except('HispanicLatinaeo', 'MidEastNAfrican')
    client_cache = GrdaWarehouse::Hud::Client.new
    # race_string caches one id set per race; limit them to this report's clients.
    report_clients = GrdaWarehouse::Hud::Client.where(id: @report.homeless_scope.select(:client_id))

    race_keys = nil
    homeless_rows = []
    totals = []

    dates = @report.iteration_dates
    dates.each do |date|
      data = races.values.to_h { |label| [label, Set.new] }
      data['None'] = Set.new

      period_scope(date).joins(:client).distinct.pluck(:client_id).each do |client_id|
        race_label = races[client_cache.race_string(destination_id: client_id, scope_limit: report_clients)]
        data[race_label || 'None'] << client_id
      end
      total_count = data.map { |_, ids| ids.count }.sum
      data = @report.enforce_min_threshold(data, 'race')
      race_keys ||= data.keys

      homeless_rows << data.map do |_race, ids|
        total_count.positive? ? ((ids.count * 100.0) / total_count).round(1) : 0.0
      end
      totals << @report.published_total(total_count)
    end

    labels = race_keys&.map { |race| race == 'None' ? 'Other or Unknown' : race }
    {
      labels: labels,
      colors: labels&.each_with_index&.to_h { |label, i| [label, settings.color(i, :race)] },
      overall: race_keys && census_shares(races, race_keys, dates.last.year),
      homeless: homeless_rows,
      totals: totals,
    }
  end

  # Census share (percent) of each race label in the statewide population; nil for the 'None'
  # bucket and for every label when the census population is missing.
  private def census_shares(races, keys, year)
    full_pop = @report.geography.population_by_race(year: year)&.to_f
    keys.map do |label|
      race_code = races.key(label)
      next nil unless race_code && full_pop&.positive?

      race_pop = @report.geography.population_by_race(race_code: race_code, year: year)
      race_pop && ((race_pop.to_f / full_pop) * 100.0).round(1)
    end
  end
end
