###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# require 'get_process_mem'
require 'memery'
module PublicReports
  class StateLevelHomelessness < ::PublicReports::Report
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::NumberHelper
    include GrdaWarehouse::UsCensusApi::Aggregates
    include Memery
    acts_as_paranoid

    validate :validate_filter_dates_span_one_year, on: :create

    def validate_filter_dates_span_one_year
      return if filter_object.start + 1.years - 1.days <= filter_object.end

      errors.add(:base, 'The start and end dates must span at least one year.')
    end

    MIN_THRESHOLD = 11

    def title
      Translation.translate('State-Level Homelessness Report Generator')
    end

    def yearly?
      settings.iteration_type.to_s == 'year'
    end

    def instance_title
      Translation.translate('State-Level Homelessness Report')
    end

    private def public_s3_directory
      'state-level-homelessness'
    end

    def url
      public_reports_warehouse_reports_state_level_homelessness_index_url(host: ENV.fetch('FQDN'), protocol: 'https')
    end

    private def controller_class
      PublicReports::WarehouseReports::StateLevelHomelessnessController
    end

    def publish!
      # This should:
      # 1. Take the contents of html and push it up to S3
      # 2. Populate the published_url field
      # 3. Populate the embed_code field
      self.class.transaction do
        unpublish_similar
        update(
          html: as_html,
          published_url: generate_publish_url, # NOTE this isn't used in this report
          embed_code: generate_embed_code, # NOTE this isn't used in this report
          state: :published,
        )
      end
      push_to_s3
    end

    # Override default push to s3 to enable multiple files
    private def push_to_s3
      bucket = s3_bucket
      sections.each do |section|
        prefix = File.join(public_s3_directory, version_slug.to_s, section.to_s)
        section_html = html_section(section)

        key = File.join(prefix, 'index.html')

        resp = s3_client.put_object(
          acl: 'public-read',
          bucket: bucket,
          key: key,
          body: section_html,
          content_disposition: 'inline',
          content_type: 'text/html',
        )
        if resp.etag
          Rails.logger.info 'Successfully uploaded report file to s3'
        else
          Rails.logger.info 'Unable to upload report file'
        end
      end
    end

    private def remove_from_s3
      bucket = s3_bucket
      prefix = public_s3_directory
      sections.each do |section|
        prefix = File.join(public_s3_directory, version_slug.to_s, section.to_s)
        key = File.join(prefix, 'index.html')
        resp = s3_client.delete_object(
          bucket: bucket,
          key: key,
        )
        if resp.delete_marker
          Rails.logger.info "Successfully removed report file from s3 (#{key})"
        else
          Rails.logger.info "Unable to remove the report file (#{key})"
        end
      end
    end

    def run_and_save!
      start_report
      pre_calculate_data
      complete_report
    end

    def view_template
      sections
    end

    def generate_publish_url_for(section)
      publish_url = if ENV['S3_PUBLIC_URL'].present?
        "#{ENV['S3_PUBLIC_URL']}/#{public_s3_directory}"
      else
        # "http://#{s3_bucket}.s3-website-#{ENV.fetch('AWS_REGION')}.amazonaws.com/#{public_s3_directory}"
        "https://#{s3_bucket}.s3.amazonaws.com/#{public_s3_directory}"
      end
      publish_url = if version_slug.present?
        "#{publish_url}/#{version_slug}/#{section}"
      else
        "#{publish_url}/#{section}"
      end
      "#{publish_url}/index.html"
    end

    def generate_embed_code_for(section)
      "<iframe width='500' height='400' src='#{generate_publish_url_for(section)}' frameborder='0' sandbox='allow-scripts'><a href='#{generate_publish_url_for(section)}'>#{instance_title} -- #{section.to_s.humanize}</a></iframe>"
    end

    def sections
      [
        :pit,
        :entering_exiting,
        :summary,
        :map,
        :who,
        :race,
        :raw,
      ].
        freeze
    end

    SCHEMA_VERSION = 2

    private def chart_data
      {
        schema_version: SCHEMA_VERSION,
        periods: period_labels,
        summary: summary,
        pit_chart: pit_chart,
        inflow_outflow: inflow_outflow,
        who: who_json,
        map: map_json,
      }.
        to_json
    end

    def renderable?
      parsed_pre_calculated_data&.dig('schema_version') == SCHEMA_VERSION
    end

    private def period_labels
      iteration_dates.map do |date|
        next date.year.to_s if yearly?

        "#{date.year} Q#{((date.month - 1) / 3) + 1}"
      end
    end

    def parsed_pre_calculated_data
      @parsed_pre_calculated_data ||= Oj.load(precalculated_data) if precalculated_data.present?
    end

    private def pre_calculate_data
      update(precalculated_data: chart_data)
    end

    private def report_scope
      # for compatibility with FilterScopes
      @filter = filter_object
      @project_types = @filter.project_type_numbers
      scope = GrdaWarehouse::ServiceHistoryEnrollment.entry
      # scope = filter_for_range(scope) # all future queries limit this by date further, adding it here just makes it slower
      scope = filter_for_user_access(scope)
      scope = filter_for_cocs(scope)
      scope = filter_for_project_type(scope)
      scope = filter_for_data_sources(scope)
      scope = filter_for_organizations(scope)
      scope = filter_for_projects(scope)
      scope
    end

    # a convenience method to ensure clients all have at least one open homeless enrollment
    # within the report period, and meet all of the other criteria, but not limited by
    # SHE record type
    private def homeless_scope
      GrdaWarehouse::ServiceHistoryEnrollment.homeless.
        open_between(start_date: filter_object.start, end_date: filter_object.end).
        where(client_id: report_scope.select(:client_id))
    end

    private def iteration_dates
      date = filter_object.start_date
      # force the start to be within the chosen date range
      date = next_iteration(date) if beginning_iteration(date) < date
      dates = []
      while date <= filter_object.end_date
        dates << beginning_iteration(date)
        date = next_iteration(date)
      end
      dates
    end

    private def next_iteration(date)
      return date.next_quarter unless yearly?

      return date.next_year
    end

    private def beginning_iteration(date)
      return date.beginning_of_quarter unless yearly?

      return date.beginning_of_year
    end

    private def end_iteration(date)
      return date.end_of_quarter unless yearly?

      return [date.end_of_year, filter_object.end_date].min
    end

    private def summary
      date = pit_counts.map(&:first).last
      start_date = date.beginning_of_year
      end_date = [date.end_of_year, filter_object.end_date].min
      scope = homeless_scope.entry.
        with_service_between(
          start_date: start_date,
          end_date: end_date,
        )
      households = scope.heads_of_households.select(:client_id).distinct.count
      homeless_clients = scope.select(:client_id).distinct.count
      unsheltered = scope.hud_project_type(4).select(:client_id).distinct.count
      counts = {
        'homeless_households' => households,
        'homeless_clients' => homeless_clients,
        'unsheltered_clients' => unsheltered,
      }
      {
        year: date.year,
        tiles: [
          { value: enforce_min_threshold(counts, 'homeless_households'), label: 'Homeless Households' },
          { value: enforce_min_threshold(counts, 'homeless_clients'), label: 'People Experiencing Homelessness' },
          { value: enforce_min_threshold(counts, 'unsheltered_percent'), label: 'Unsheltered' },
        ],
      }
    end

    def map_colors
      @map_colors ||= {}.tap do |m_colors|
        colors = ['#FFFFFF']
        8.times do |i|
          colors << settings["color_#{i}"]
        end
        if settings.map_overall_geography_census?
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

    # Returns [labels, note]. A label carries a trailing "*" when its PIT
    # year extends beyond the report's end date (a partial year); note
    # explains the asterisk when any label carries one.
    private def year_labels_and_note(dates)
      labels = []
      partial_year_date = nil
      dates.each do |date|
        if date.end_of_year > filter_object.end_date
          labels << "#{date.year}*"
          partial_year_date ||= date
        else
          labels << date.year.to_s
        end
      end
      note = "#{partial_year_date.year} reflects data through #{filter_object.end_date.strftime('%b %-d, %Y')}" if partial_year_date
      [labels, note]
    end

    private def pit_chart
      dates = pit_counts.map(&:first)
      labels, note = year_labels_and_note(dates)
      values = pit_counts.map { |_date, count| enforce_min_threshold(count, 'pit_chart') }
      chart = {
        labels: labels,
        series: [{ label: 'People served in ES, SO, SH, or TH', values: values }],
      }
      chart[:note] = note if note
      chart
    end

    private def inflow_outflow
      dates = inflow_out_flow_counts.map(&:first)
      labels, note = year_labels_and_note(dates)
      ins = inflow_out_flow_counts.map { |_date, in_count, _out_count| enforce_min_threshold(in_count, 'inflow_outflow') }
      outs = inflow_out_flow_counts.map { |_date, _in_count, out_count| enforce_min_threshold(out_count, 'inflow_outflow') }
      chart = {
        labels: labels,
        series: [
          { label: 'People entering ES, SO, SH, or TH (first time homeless)', values: ins },
          { label: 'People exiting ES, SO, SH, or TH to a permanent destination', values: outs },
        ],
      }
      chart[:note] = note if note
      chart
    end

    private def pit_count_dates
      year = filter_object.start.year
      dates = []
      while year < filter_object.end.year + 1
        d = Date.new(year, 1, -1)
        d -= (d.wday - 3) % 7
        dates << d
        year += 1
      end
      dates.select { |date| date.between?(filter_object.start, filter_object.end) }
    end

    private def pit_counts
      pit_count_dates.map do |date|
        start_date = date.beginning_of_year
        end_date = [date.end_of_year, filter_object.end_date].min
        count = homeless_scope.entry.
          with_service_between(
            start_date: start_date,
            end_date: end_date,
          ).
          select(:client_id).
          distinct.
          count
        [
          date,
          count,
        ]
      end
    end

    private def inflow_out_flow_counts
      pit_count_dates.map do |date|
        start_date = date.beginning_of_year
        end_date = [date.end_of_year, filter_object.end_date].min
        in_count = homeless_scope.first_date.
          started_between(start_date: start_date, end_date: end_date).
          select(:client_id).
          distinct.
          count
        out_count = homeless_scope.entry.
          exit_within_date_range(start_date: start_date, end_date: end_date).
          where(destination: ::HudHelper.util.permanent_destinations).
          select(:client_id).
          distinct.
          count
        [
          date,
          in_count,
          out_count,
        ]
      end
    end

    # counts_by_period: one raw-count array per iteration_dates entry, in labels order.
    private def donut(title:, unit:, labels:, colors:, counts_by_period:, threshold_key:)
      values = []
      totals = []
      counts_by_period.each do |counts|
        total = counts.sum
        totals << (total.positive? && total <= 100 ? nil : total)
        values << enforce_min_threshold(counts.dup, threshold_key)
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

    private def all_people_donut
      counts_by_period = iteration_dates.map do |date|
        scope = homeless_scope.with_service_between(
          start_date: beginning_iteration(date),
          end_date: end_iteration(date),
        )
        [
          scope.homeless_sheltered.select(:client_id).distinct.count,
          scope.homeless_unsheltered.select(:client_id).distinct.count,
        ]
      end
      donut(
        title: 'All People',
        unit: 'People',
        labels: ['Sheltered', 'Unsheltered'],
        colors: [settings.color(0, :location_type), settings.color(1, :location_type)],
        counts_by_period: counts_by_period,
        threshold_key: 'location',
      )
    end

    private def veterans_donut
      counts_by_period = iteration_dates.map do |date|
        scope = homeless_scope.with_service_between(
          start_date: beginning_iteration(date),
          end_date: end_iteration(date),
        ).veteran
        [
          scope.homeless_sheltered.select(:client_id).distinct.count,
          scope.homeless_unsheltered.select(:client_id).distinct.count,
        ]
      end
      donut(
        title: 'Veterans',
        unit: 'Veterans',
        labels: ['Sheltered', 'Unsheltered'],
        colors: [settings.color(0, :location_type), settings.color(1, :location_type)],
        counts_by_period: counts_by_period,
        threshold_key: 'location',
      )
    end

    private def household_type_donut
      counts_by_period = iteration_dates.map do |date|
        start_date = beginning_iteration(date)
        end_date = end_iteration(date)
        [
          adult_only_household_ids(start_date, end_date).values.uniq.count,
          adult_and_child_household_ids(start_date, end_date).values.uniq.count,
          child_only_household_ids(start_date, end_date).values.uniq.count,
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

    private def who_json
      {
        periods: period_labels,
        currentIndex: period_labels.size - 1,
        donuts: {
          'all-people' => all_people_donut,
          'veterans' => veterans_donut,
          'household-type' => household_type_donut,
        },
        race: race_chart,
        raceTitleCategories: ['Homeless Population', 'Overall Population'],
        breakdown: homeless_breakdowns,
        breakdownGroupings: breakdown_groupings,
      }
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

      dates = iteration_dates
      dates.each_with_index do |date, index|
        start_date = beginning_iteration(date)
        end_date = end_iteration(date)
        client_ids = Set.new
        data = {}
        census_data = {}
        races.each do |race_code, label|
          data[label] ||= Set.new
          full_pop = get_us_census_population_by_race(year: date.year) || 0
          race_pop = get_us_census_population_by_race(race_code: race_code, year: date.year) || 0
          census_data[label] = full_pop.positive? ? (race_pop / full_pop.to_f) * 100.0 : 0.0
        end

        scope = homeless_scope.with_service_between(
          start_date: start_date,
          end_date: end_date,
        )
        scope.joins(:client).preload(:client).
          order(first_date_in_program: :desc). # Use the newest start
          find_each do |enrollment|
            client = enrollment.client
            race_code = client_cache.race_string(destination_id: client.id)
            race_label = races[race_code]
            data[race_label] << client.id if race_label && ! client_ids.include?(client.id)
            client_ids << client.id
          end
        total_count = data.map { |_, ids| ids.count }.sum
        data = enforce_min_threshold(data, 'race')

        labels ||= data.keys.map { |race| race == 'None' ? 'Other or Unknown' : race }
        colors ||= labels.each_with_index.to_h { |label, i| [label, settings.color(i, :race)] }

        homeless_rows << data.map do |_race, ids|
          total_count.positive? ? ((ids.count * 100.0) / total_count).round(1) : 0.0
        end
        totals << total_count

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

    MAP_GROUP_LABELS = [
      'All Homeless',
      'Youth and Young Adults (age 18-24)',
      'Adults in Adult Only Households (age 18+)',
      'Adults with Children',
      'Veterans',
    ].freeze

    # [scope, service_scope] for one map group, index-aligned with MAP_GROUP_LABELS.
    private def map_group_scope(index)
      case index
      when 0
        [homeless_scope, :current_scope]
      when 1
        @filter = filter_object.deep_dup
        @filter.age_ranges = [:eighteen_to_twenty_four]
        [filter_for_age(homeless_scope), GrdaWarehouse::ServiceHistoryService.aged(18..24)]
      when 2
        [homeless_scope.adult_only_households, :current_scope]
      when 3
        [homeless_scope.adults_with_children, :current_scope]
      when 4
        [homeless_scope.veterans, :current_scope]
      end
    end

    # Snaps a rate to the upper bound of the map_colors bucket it falls into.
    private def snap_rate(rate)
      bucket = map_colors.values.detect { |b| rate <= b[:high] }
      (bucket || map_colors.values.last)[:high]
    end

    private def map_json
      dates = iteration_dates
      geographies = map_geography
      towns = geographies.map { |code| map_geography_display_name(code) }
      populations = geographies.map { |code| overall_population_geography(dates.last.year, code) }
      group_scopes = (0...MAP_GROUP_LABELS.size).map { |i| map_group_scope(i) }

      values = []
      statewide_totals = []

      dates.each do |date|
        start_date = beginning_iteration(date)
        end_date = end_iteration(date)
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
          period_totals << (overall_homeless_population.positive? && overall_homeless_population <= 100 ? nil : overall_homeless_population)

          period_values << geographies.map do |code|
            population_overall = overall_population_geography(date.year, code)
            next nil if settings.map_overall_geography_census? && population_overall.to_i.zero?

            homeless_count = count_homeless_population(
              scope: scope,
              start_date: start_date,
              end_date: end_date,
              service_scope: service_scope,
              overall_homeless_population: overall_homeless_population,
              code: code,
            )
            homeless_count = enforce_min_threshold(homeless_count, 'min_threshold') unless settings.map_overall_geography_census?

            denominator = map_tooltip_denominator(population_overall, overall_homeless_population)
            rate = denominator&.positive? ? (homeless_count / denominator.to_f) * 100.0 : 0.0
            snap_rate(rate.round(1))
          end
        end

        values << period_values
        statewide_totals << period_totals
      end

      {
        towns: towns,
        periods: period_labels,
        groups: MAP_GROUP_LABELS,
        values: values,
        populations: populations,
        statewideTotals: statewide_totals,
        bands: map_colors.map { |color, info| { max: info[:high], color: color, label: info[:description] } },
        notReportingColor: settings.theme[:not_reporting],
        unit: settings.map_overall_geography_census? ? 'Rate per 10,000 population' : 'Percentage of homeless population',
      }
    end

    # Geography codes, ordered by display name (Task 3.9). Code and display
    # name are the same value for zip/place/county; only CoC differs
    # (code is cocnum, display name is "name (cocnum)").
    private def map_geography
      return state_zip_shapes.map(&:zcta5ce10).sort if map_by_zip?
      return state_place_shapes.map(&:name).sort if map_by_place?
      return state_county_shapes.map(&:name).sort if map_by_county?

      state_coc_shapes.sort_by(&:number_and_name).map(&:cocnum)
    end

    private def map_geography_display_name(code)
      return code if map_by_zip? || map_by_place? || map_by_county?

      coc_display_names[code] || code
    end

    private def coc_display_names
      @coc_display_names ||= state_coc_shapes.index_by(&:cocnum).transform_values(&:number_and_name)
    end

    private def overall_population_geography(year, code)
      # For testing
      # return 10_000 unless Rails.env.production?
      return (500..2_000).to_a.sample unless Rails.env.production?

      count = if map_by_zip?
        population_by_zip.try(:[], year).try(:[], code)
      elsif map_by_place?
        population_by_place.try(:[], year).try(:[], code)
      elsif map_by_county?
        population_by_county.try(:[], year).try(:[], code)
      else
        population_by_coc.try(:[], year).try(:[], code)
      end

      count || 0
    end

    private def homeless_population_overall(scope:, start_date:, end_date:, service_scope:, population_overall:)
      if Rails.env.production?
        scope.with_service_between(
          start_date: start_date,
          end_date: end_date,
          service_scope: service_scope,
        ).count
      else
        # This should change across quarter, but not geography
        max = [population_overall, 1].compact.max / 3
        @fake_overall_homeless_pop_per_quarter ||= {}
        @fake_overall_homeless_pop_per_quarter[start_date] ||= {}
        @fake_overall_homeless_pop_per_quarter[start_date][scope.to_s] ||= (0..max).to_a.sample
        @fake_overall_homeless_pop_per_quarter[start_date][scope.to_s]
      end
    end

    private def count_homeless_population(scope:, start_date:, end_date:, service_scope:, overall_homeless_population:, code:)
      if Rails.env.production?
        enrolled_scope = scope.with_service_between(
          start_date: start_date,
          end_date: end_date,
          service_scope: service_scope,
        )
        if map_by_zip?
          enrolled_scope.in_zip(zip_code: code).count
        elsif map_by_place?
          enrolled_scope.in_place(place: code).count
        elsif map_by_county?
          enrolled_scope.in_county(county: code).count
        else
          enrolled_scope.in_coc(coc_code: code).count
        end
      else
        max = [overall_homeless_population, 1].compact.max / 3
        (0..max).to_a.sample
        # for testing
        # 16
      end
    end

    # denominator is either state-wide homeless population
    # or census population for chosen geography
    private def map_tooltip_denominator(population_overall, overall_homeless_population)
      return population_overall.to_f / 100 if settings.map_overall_geography_census?

      overall_homeless_population.to_f
    end

    # rowId => { totals:, chronic:, sheltered:, unsheltered: }, one array entry per iteration_dates period.
    private def homeless_breakdowns
      dates = iteration_dates
      num_periods = dates.size
      rows = {}

      dates.each_with_index do |date, date_index|
        start_date = beginning_iteration(date)
        end_date = end_iteration(date)
        shs_scope = GrdaWarehouse::ServiceHistoryService.where(date: start_date..end_date)
        base_scope = homeless_scope.with_service_between(
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
          compute_breakdown_rows(
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
          compute_breakdown_rows(
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
          compute_breakdown_rows(
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

    private def compute_breakdown_rows(rows:, grouping:, section_index:, setup:, scope:, date_index:, num_periods:, combine_rows:)
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

        if combine_rows
          chronic_count = combined_chronic_count
          total_count = combined_total_count
        end

        rows[row_id][:totals][date_index] = total_count.positive? && total_count <= 100 ? nil : total_count
        rows[row_id][:chronic][date_index] = enforce_min_threshold([chronic_count, total_count], 'chronic_percents')

        if sheltered_count < MIN_THRESHOLD || unsheltered_count < MIN_THRESHOLD
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

    private def breakdown_groupings
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

    private def households(start_date, end_date)
      households = {}
      counted_ids = Set.new
      shs_scope = GrdaWarehouse::ServiceHistoryService.where(date: start_date..end_date)
      homeless_scope.with_service_between(
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

    private def adult_and_child_household_ids(start_date, end_date)
      adult_and_child_households = {}
      households(start_date, end_date).each do |hh_id, household|
        child_present = household[:ages].any? { |age| age < 18 }
        adult_present = household[:ages].any? { |age| age >= 18 }
        adult_and_child_households[hh_id] = household[:hoh_client_id] if child_present && adult_present
      end
      adult_and_child_households
    end
    memoize :adult_and_child_household_ids

    private def child_only_household_ids(start_date, end_date)
      child_only_households = {}
      households(start_date, end_date).each do |hh_id, household|
        child_present = household[:ages].any? { |age| age < 18 }
        adult_present = household[:ages].any? { |age| age >= 18 }
        child_only_households[hh_id] = household[:hoh_client_id] if child_present && ! adult_present
      end
      child_only_households
    end
    memoize :child_only_household_ids

    private def adult_only_household_ids(start_date, end_date)
      adult_only_household_ids = {}
      households(start_date, end_date).each do |hh_id, household|
        child_present = household[:ages].any? { |age| age < 18 }
        # Include clients of unknown age
        adult_only_household_ids[hh_id] = household[:hoh_client_id] unless child_present
      end
      adult_only_household_ids
    end
    memoize :adult_only_household_ids

    # Pre-projected SVG paths for the current map type, one per map_geography
    # entry (same order). No per-vertex Ruby: the projection, translation and
    # scaling happen in PostGIS.
    def map_svg
      cache_key = "map-svg-#{settings.map_type}-#{GrdaWarehouse::Config.relevant_state_codes.join('_')}"
      Rails.cache.fetch(cache_key, expires_in: 4.hours) do
        calculate_map_svg
      end
    end

    private def map_shape_class
      return GrdaWarehouse::Shape::ZipCode if map_by_zip?
      return GrdaWarehouse::Shape::Town if map_by_place?
      return GrdaWarehouse::Shape::County if map_by_county?

      GrdaWarehouse::Shape::Coc
    end

    private def map_geometry_code_column
      return 'zcta5ce10' if map_by_zip?
      return 'town' if map_by_place?
      return 'namelsad' if map_by_county?

      'cocnum'
    end

    private def calculate_map_svg
      scope = map_shape_class.my_states

      # Cast to text: ST_Extent returns Postgres's `box` type, which the PG
      # adapter has no OID mapping for. Left uncast, the adapter's fallback
      # to treating it as a string emits a Ruby warning -- harmless on its
      # own, but this app's Warning.process (custom_deprecation_handler.rb)
      # turns every warning into a hard raise in development.
      extent = scope.pick(Arel.sql('ST_Extent(ST_Transform(COALESCE(simplified_geom, geom), 3857))::text'))
      xmin, ymin, xmax, ymax = extent.scan(/[-\d.]+/).map(&:to_f)
      scale = 720.0 / (xmax - xmin)
      height = ((ymax - ymin) * scale).round(2)

      d_by_code = scope.pluck(
        Arel.sql(map_geometry_code_column),
        Arel.sql("ST_AsSVG(ST_TransScale(ST_Transform(COALESCE(simplified_geom, geom), 3857), #{-xmin}, #{-ymax}, #{scale}, #{scale}), 0, 1)"),
      ).to_h

      paths = map_geography.each_with_index.map do |code, index|
        [index, code.to_s.parameterize, d_by_code[code]]
      end

      { view_box: "0 0 720 #{height}", paths: paths }
    end

    private def get_us_census_population_by_race(race_code: 'All', year:)
      race_var = \
        case race_code
        when 'AmIndAKNative' then NATIVE_AMERICAN
        when 'Asian' then ASIAN
        when 'BlackAfAmerican' then BLACK
        when 'NativeHIPacific' then PACIFIC_ISLANDER
        when 'White' then WHITE
        when 'RaceNone' then OTHER_RACE
        when 'MultiRacial' then TWO_OR_MORE_RACES
        when 'All' then ALL_PEOPLE
        else
          raise "Invalid race code: #{race_code}"
        end

      results = geometries.map do |geo|
        geo.population(internal_names: race_var, year: year)
      end

      results.each do |result|
        if result.error
          Rails.logger.error "population error: #{result.msg}. Sum won't be right!"
          return nil
        elsif result.year != year
          Rails.logger.warn "Using #{result.year} instead of #{year}"
        end
      end

      results.map(&:val).sum
    end

    # COC CODES
    private def geometries
      @geometries ||= GrdaWarehouse::Shape::Coc.where(cocnum: coc_codes)
    end

    private def state_coc_shapes
      @state_coc_shapes ||= GrdaWarehouse::Shape::Coc.my_states
    end

    private def coc_codes
      @coc_codes ||= state_coc_shapes.map(&:cocnum)
    end

    private def population_by_coc
      @population_by_coc ||= {}.tap do |charts|
        iteration_dates.map(&:year).uniq.each do |year|
          charts[year] = {}
          geometries.each do |coc|
            charts[year][coc.cocnum] = coc.population(internal_names: ALL_PEOPLE, year: year).val
          end
        end
      end
    end

    # ZIP CODES
    def map_by_zip?
      settings.map_type == 'zip'
    end

    def map_by_place?
      settings.map_type == 'place'
    end

    def map_by_county?
      settings.map_type == 'county'
    end

    def map_type_human
      return 'ZIP code' if map_by_zip?
      return 'town' if map_by_place?
      return 'county' if map_by_county?

      'Continuum of Care'
    end

    private def zip_geometries
      @zip_geometries ||= GrdaWarehouse::Shape::ZipCode.where(zcta5ce10: zip_codes)
    end

    private def zip_codes
      @zip_codes ||= state_zip_shapes.map(&:zcta5ce10)
    end

    private def state_zip_shapes
      @state_zip_shapes ||= GrdaWarehouse::Shape::ZipCode.my_states
    end

    private def population_by_zip
      @population_by_zip ||= {}.tap do |charts|
        iteration_dates.map(&:year).uniq.each do |year|
          charts[year] = {}
          zip_geometries.each do |geo|
            charts[year][geo.zcta5ce10] ||= geo.population(internal_names: ALL_PEOPLE, year: year).val
          end
        end
      end
    end

    private def county_geometries
      @county_geometries ||= GrdaWarehouse::Shape::County.where(namelsad: county_codes)
    end

    private def county_codes
      @county_codes ||= state_county_shapes.map(&:namelsad)
    end

    private def state_county_shapes
      @state_county_shapes ||= GrdaWarehouse::Shape::County.my_states
    end

    private def population_by_county
      @population_by_county ||= {}.tap do |charts|
        iteration_dates.map(&:year).uniq.each do |year|
          charts[year] = {}
          county_geometries.each do |geo|
            charts[year][geo.name] ||= geo.population(internal_names: ALL_PEOPLE, year: year).val
          end
        end
      end
    end

    private def place_geometries
      @place_geometries ||= GrdaWarehouse::Shape::Town.where(town: place_codes)
    end

    private def place_codes
      @place_codes ||= state_place_shapes.map(&:name)
    end

    private def state_place_shapes
      @state_place_shapes ||= GrdaWarehouse::Shape::Town.my_states
    end

    private def population_by_place
      @population_by_place ||= {}.tap do |charts|
        iteration_dates.map(&:year).uniq.each do |year|
          charts[year] = {}
          place_geometries.each do |geo|
            charts[year][geo.name] ||= geo.population(internal_names: ALL_PEOPLE, year: year).val
          end
        end
      end
    end
  end
end
