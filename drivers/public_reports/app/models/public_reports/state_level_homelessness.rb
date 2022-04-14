###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# require 'get_process_mem'
require 'memoist'
module PublicReports
  class StateLevelHomelessness < ::PublicReports::Report
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::NumberHelper
    include GrdaWarehouse::UsCensusApi::Aggregates
    extend Memoist
    acts_as_paranoid

    MIN_THRESHOLD = 11

    attr_accessor :map_max_rate, :map_max_count

    def title
      _('State-Level Homelessness Report Generator')
    end

    def instance_title
      _('State-Level Homelessness Report')
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
        :summary,
        :map,
        :who,
        :raw,
      ].
        freeze
    end

    def populations
      {
        youth: _('Youth and Young Adults'),
        adults: _('Adult-Only Households'),
        adults_with_children: _('Adults with Children'),
        veterans: _('Veterans'),
      }
    end

    def household_types
      {
        adults: _('Adult-Only Households'),
        adults_with_children: _('Adults with Children'),
        children: _('Child-Only Households'),
      }
    end

    private def chart_data
      {
        # count: percent_change_in_count,
        date_range: filter_object.date_range_words,
        quarters: quarter_dates,
        summary: summary,
        # pit_chart: pit_chart,
        # inflow_outflow: inflow_outflow,
        # location_chart: location_chart,
        # household_type: household_type,
        # race_chart: race_chart,
        need_map: enforce_min_threshold(need_map, 'need_map'),
        homeless_breakdowns: homeless_breakdowns,
        map_max_rate: map_max_rate,
        map_max_count: map_max_count,
      }.
        to_json
    end

    def parsed_pre_calculated_data
      @parsed_pre_calculated_data ||= Oj.load(precalculated_data) if precalculated_data.present?
    end

    private def pre_calculate_data
      update(precalculated_data: chart_data)
    end

    private def report_scope
      # for compatability with FilterScopes
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

    private def quarter_dates
      date = filter_object.start_date
      # force the start to be within the chosen date range
      date = date.next_quarter if date.beginning_of_quarter < date
      dates = []
      while date <= filter_object.end_date
        dates << date.beginning_of_quarter
        date = date.next_quarter
      end
      dates
    end

    private def summary
      date = pit_counts.map(&:first).last
      start_date = date.beginning_of_year
      end_date = date.end_of_year
      scope = homeless_scope.entry.
        with_service_between(
          start_date: start_date,
          end_date: end_date,
        )
      households = scope.heads_of_households.select(:client_id).distinct.count
      homeless_clients = scope.select(:client_id).distinct.count
      unsheltered = scope.hud_project_type(4).select(:client_id).distinct.count
      {
        year: date.year,
        date: date,
        homeless_households: households,
        homeless_clients: homeless_clients,
        unsheltered_clients: unsheltered,
      }
    end

    def map_colors
      @map_colors ||= {}.tap do |m_colors|
        # slight = 0.000001
        # ten_percent = 9.999999
        # max_rate = parsed_pre_calculated_data.try(:[], 'map_max_rate') || map_max_rate
        # colors = chart_color_shades(:map_primary_color)
        colors = ['#FFFFFF']
        5.times do |i|
          colors << settings["color_#{i}"]
        end
        if settings.map_overall_geography_census?
          m_colors[colors[0]] = { description: 'None', range: (0..0), low: 0, high: 0 }
          m_colors[colors[1]] = { description: 'Any - 15 per 10,000', range: (0.000001..15.0), low: 0.000001, high: 15.0 }
          # m_colors[colors[2]] = { description: '11 - 15 per 10,000', range: (10.000001..15.0), low: 10.000001, high: 15.0 }
          m_colors[colors[3]] = { description: '16 - 20 per 10,000', range: (15.000001..20.0), low: 15.000001, high: 20.0 }
          m_colors[colors[4]] = { description: '21 - 25 per 10,000', range: (20.000001..25.0), low: 20.000001, high: 25.0 }
          m_colors[colors[5]] = { description: '26+ per 10,000', range: (25.000001..100.0), low: 25.000001, high: 100.0 }
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

    private def pit_chart
      x = ['x']
      y = ['People served in ES, SO, SH, or TH']
      pit_counts.each do |date, count|
        x << date
        y << enforce_min_threshold(count, 'pit_chart')
      end
      [x, y].to_json
    end

    private def inflow_outflow
      x = ['x']
      ins = ['People entering ES, SO, SH, or TH (first time homeless)']
      outs = ['People exiting ES, SO, SH, or TH to a permanent destination']
      inflow_out_flow_counts.each do |date, in_count, out_count|
        x << date
        ins << enforce_min_threshold(in_count, 'inflow_outflow')
        outs << enforce_min_threshold(out_count, 'inflow_outflow')
      end
      [x, ins, outs].to_json
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
        end_date = date.end_of_year
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
        end_date = date.end_of_year
        in_count = homeless_scope.first_date.
          started_between(start_date: start_date, end_date: end_date).
          select(:client_id).
          distinct.
          count
        out_count = homeless_scope.entry.
          exit_within_date_range(start_date: start_date, end_date: end_date).
          where(destination: ::HUD.permanent_destinations).
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

    private def location_chart
      {}.tap do |charts|
        charts[:all_homeless] = {}
        charts[:homeless_veterans] = {}
        quarter_dates.each do |date|
          start_date = date.beginning_of_quarter
          end_date = date.end_of_quarter
          scope = homeless_scope.with_service_between(
            start_date: start_date,
            end_date: end_date,
          )
          sheltered = scope.homeless_sheltered.select(:client_id).distinct.count
          unsheltered = scope.homeless_unsheltered.select(:client_id).distinct.count
          (sheltered, unsheltered) = enforce_min_threshold([sheltered, unsheltered], 'location')

          charts[:all_homeless][date.iso8601] = {
            data: [
              ['Sheltered', sheltered],
              ['Unsheltered', unsheltered],
            ],
            total: total_for(scope, nil),
          }
          sheltered = scope.homeless_sheltered.veteran.select(:client_id).distinct.count
          unsheltered = scope.homeless_unsheltered.veteran.select(:client_id).distinct.count
          (sheltered, unsheltered) = enforce_min_threshold([sheltered, unsheltered], 'location')
          charts[:homeless_veterans][date.iso8601] = {
            data: [
              ['Sheltered', sheltered],
              ['Unsheltered', unsheltered],
            ],
            total: total_for(scope.veteran, :veterans),
          }
        end
      end
    end

    private def household_type
      {}.tap do |charts|
        quarter_dates.each do |date|
          start_date = date.beginning_of_quarter
          end_date = date.end_of_quarter

          adult = adult_only_household_ids(start_date, end_date).count
          both = adult_and_child_household_ids(start_date, end_date).count
          child = child_only_household_ids(start_date, end_date).count
          total = adult + both + child
          (adult, both, child) = enforce_min_threshold([adult, both, child], 'household_type')
          word = 'Household'
          total = if total < 100
            "less than #{pluralize(100, word)}"
          else
            pluralize(number_with_delimiter(total), word)
          end
          charts[date.iso8601] = {
            data: [
              ['Adult Only', adult],
              ['Adults with Children', both],
              ['Children-Only Households', child],
            ],
            total: total,
          }
        end
      end
    end

    private def race_chart
      {}.tap do |charts|
        client_cache = GrdaWarehouse::Hud::Client.new
        # Manually do HUD race lookup to avoid a bunch of unnecessary mapping and lookups
        races = ::HUD.races(multi_racial: true)
        quarter_dates.each do |date|
          start_date = date.beginning_of_quarter
          end_date = date.end_of_quarter
          client_ids = Set.new
          data = {}
          census_data = {}
          # Add census info
          races.each do |race_code, label|
            census_data[label] = 0
            data[races[race_code]] ||= Set.new
            year = date.year
            full_pop = get_us_census_population_by_race(year: year) || 0
            race_pop = get_us_census_population_by_race(race_code: race_code, year: year) || 0
            census_data[label] = race_pop / full_pop.to_f if full_pop.positive?
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
              data[races[race_code]] << client.id unless client_ids.include?(client.id)
              client_ids << client.id
            end
          total_count = data.map { |_, ids| ids.count }.sum
          data = enforce_min_threshold(data, 'race')
          # Format:
          # [["Black or African American",38, 53],["White",53, 76],["Native Hawaiian or Other Pacific Islander",1, 12],["Multi-Racial",4, 10],["Asian",1, 5],["American Indian or Alaska Native",1, 1]]
          combined_data = data.map do |race, ids|
            label = if race == 'None'
              'Other or Unknown'
            else
              race
            end
            [
              label,
              ids.count / total_count.to_f, # Homeless Data
              census_data[race], # Federal Census Data
            ]
          end
          charts[date.iso8601] = {
            # then the title for the tooltip needs to be adjusted for 0, 1 where 0 is homeless population, 1 is whole population
            # data for census population is stored in GrdaWarehouse::FederalCensusBreakdowns:Coc
            # get distinct on max date prior to date in question with identifier and measure
            # use distinct ProjectCoC.CoCCodes to determine the scope for census data
            # sum value after getting appropriate set of rows
            # add index on [accurate_on, identifier, type, measure]
            data: combined_data,
            title: _('Racial Composition'),
            total: total_for(scope, nil),
            categories: ['Homeless Population', 'Overall Population'],
          }
        end
      end
    end

    private def need_map
      {
        homeless_map: homeless_map,
        youth_homeless_map: youth_homeless_map,
        adults_homeless_map: adults_homeless_map,
        adults_with_children_homeless_map: adults_with_children_homeless_map,
        veterans_homeless_map: veterans_homeless_map,
      }
    end

    # Counts and rate of homeless individuals by CoC
    private def homeless_map
      scope = homeless_scope
      census_comparison_map_data(scope)
    end

    private def youth_homeless_map
      @filter = filter_object.deep_dup
      @filter.age_ranges = [:eighteen_to_twenty_four]
      scope = filter_for_age(homeless_scope)
      service_scope = GrdaWarehouse::ServiceHistoryService.aged(18..24)
      census_comparison_map_data(scope, service_scope: service_scope)
    end

    private def adults_homeless_map
      scope = homeless_scope.adult_only_households
      census_comparison_map_data(scope)
    end

    private def adults_with_children_homeless_map
      scope = homeless_scope.adults_with_children
      census_comparison_map_data(scope)
    end

    private def veterans_homeless_map
      scope = homeless_scope.veterans
      census_comparison_map_data(scope)
    end

    private def map_geography
      return zip_codes if map_by_zip?
      return place_codes if map_by_place?
      return county_codes if map_by_county?

      coc_codes
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

    private def census_comparison_map_data(scope, service_scope: :current_scope)
      self.map_max_rate ||= 0
      self.map_max_count ||= 0
      {}.tap do |charts|
        quarter_dates.each do |date|
          iso_date = date.iso8601
          start_date = date.beginning_of_quarter
          end_date = date.end_of_quarter
          charts[iso_date] = {}
          map_geography.each do |code|
            population_overall = overall_population_geography(date.year, code)
            overall_homeless_population = homeless_population_overall(
              scope: scope,
              start_date: start_date,
              end_date: end_date,
              service_scope: service_scope,
              population_overall: population_overall,
            )
            homeless_count = count_homeless_population(
              scope: scope,
              start_date: start_date,
              end_date: end_date,
              service_scope: service_scope,
              overall_homeless_population: overall_homeless_population,
              code: code,
            )

            homeless_count = enforce_min_threshold(homeless_count, 'min_threshold') unless settings.map_overall_geography_census?
            # % of homeless population or rate per 10,000 of overall population
            denominator = map_tooltip_denominator(population_overall, overall_homeless_population)
            rate = 0
            rate = homeless_count / denominator.to_f * 100.0 if denominator&.positive?
            charts[iso_date][code] = {
              count: overall_homeless_population,
              overall_population: population_overall.to_i,
              rate: rate.round(1),
              homeless_count: homeless_count,
            }
            self.map_max_rate = rate if rate > self.map_max_rate
            self.map_max_count = homeless_count if homeless_count > self.map_max_count
          end
        end
      end
    end

    # denominator is either state-wide homeless population
    # or census population for chosen geography
    private def map_tooltip_denominator(population_overall, overall_homeless_population)
      return population_overall.to_f / 100 if settings.map_overall_geography_census?

      overall_homeless_population.to_f
    end

    private def homeless_breakdowns
      {
        adult_only: adult_only_household_breakdowns,
        adult_and_child: adult_and_child_household_breakdowns,
        child_only: child_only_household_breakdowns,
        gender: gender_breakdowns,
        race: race_breakdowns,
      }
    end

    private def homeless_chart_breakdowns(section_title:, charts:, setup:, scope:, date:)
      iso_date = date.iso8601
      section_chronic_count = 0
      section_total_count = 0
      chronic_scope = scope.joins(enrollment: :ch_enrollment).
        merge(GrdaWarehouse::ChEnrollment.chronically_homeless)

      # NOTE: for adults with children we sum all categories together
      if section_title.downcase == 'Persons in households with at least one child and one adult'.downcase
        setup.each do |_, client_scope|
          section_chronic_count += chronic_scope.where(client_id: scope.merge(client_scope).distinct.pluck(:client_id)).count
          section_total_count += scope.merge(client_scope).distinct.select(:client_id).count
        end
      end

      setup.each do |title, client_scope|
        chronic_count = chronic_scope.where(client_id: scope.merge(client_scope).distinct.pluck(:client_id)).count
        sheltered_count = scope.homeless_sheltered.merge(client_scope).select(:client_id).distinct.count
        unsheltered_count = scope.homeless_unsheltered.merge(client_scope).select(:client_id).distinct.count
        charts[section_title] ||= {
          'sub_sections' => {},
          'chronic_counts' => {},
          'total_counts' => {},
          'chronic_percents' => {},
        }

        total_string = total_for(scope.merge(client_scope), nil)
        total_count = scope.merge(client_scope).distinct.select(:client_id).count

        if section_title.downcase == 'Persons in households with at least one child and one adult'.downcase
          chronic_count = section_chronic_count
          total_count = section_total_count
        end
        charts[section_title]['chronic_counts'][iso_date] ||= {}
        charts[section_title]['chronic_counts'][iso_date][title] ||= 0
        charts[section_title]['chronic_counts'][iso_date][title] = chronic_count
        charts[section_title]['chronic_percents'][iso_date] ||= {}
        charts[section_title]['chronic_percents'][iso_date][title] ||= 0
        charts[section_title]['chronic_percents'][iso_date][title] = enforce_min_threshold([chronic_count, total_count], 'chronic_percents')
        charts[section_title]['sub_sections'][title] ||= {}
        charts[section_title]['sub_sections'][title][iso_date] = {
          total: total_string,
          data: [
            ['Sheltered', sheltered_count],
            ['Unsheltered', unsheltered_count],
          ],
          categories: [title],
        }
      end
    end

    private def adult_only_household_breakdowns
      setup = {
        'Persons Age 18 to 24' => GrdaWarehouse::ServiceHistoryEnrollment.joins(:service_history_services).merge(GrdaWarehouse::ServiceHistoryService.aged(18..24)),
        'Persons over age 24' => GrdaWarehouse::ServiceHistoryEnrollment.joins(:service_history_services).merge(GrdaWarehouse::ServiceHistoryService.aged(24..105)),
        'Persons of unknown age' => GrdaWarehouse::ServiceHistoryEnrollment.joins(:service_history_services).merge(GrdaWarehouse::ServiceHistoryService.unknown_age),
      }
      {}.tap do |charts|
        quarter_dates.each do |date|
          start_date = date.beginning_of_quarter
          end_date = date.end_of_quarter

          shs_scope = GrdaWarehouse::ServiceHistoryService.
            where(date: start_date..end_date)
          quarter_setup = {}
          setup.each do |k, v|
            quarter_setup[k] = v.merge(shs_scope)
          end
          scope = homeless_scope.with_service_between(
            start_date: start_date,
            end_date: end_date,
            service_scope: shs_scope,
          ).
            joins(:client)
          adult_only_scope = scope.where(household_id: adult_only_household_ids(start_date, end_date))

          homeless_chart_breakdowns(
            section_title: 'Persons in Households Without Children',
            charts: charts,
            setup: quarter_setup,
            scope: adult_only_scope,
            date: date,
          )
        end
      end
    end

    private def adult_and_child_household_breakdowns
      setup = {
        'Children under 18' => GrdaWarehouse::ServiceHistoryEnrollment.joins(:service_history_services).merge(GrdaWarehouse::ServiceHistoryService.aged(0..17)),
        'Persons Age 18 to 24' => GrdaWarehouse::ServiceHistoryEnrollment.joins(:service_history_services).merge(GrdaWarehouse::ServiceHistoryService.aged(18..24)),
        'Persons over age 24' => GrdaWarehouse::ServiceHistoryEnrollment.joins(:service_history_services).merge(GrdaWarehouse::ServiceHistoryService.aged(24..105)),
        'Persons of unknown age' => GrdaWarehouse::ServiceHistoryEnrollment.joins(:service_history_services).merge(GrdaWarehouse::ServiceHistoryService.unknown_age),
      }
      {}.tap do |charts|
        quarter_dates.each do |date|
          start_date = date.beginning_of_quarter
          end_date = date.end_of_quarter

          shs_scope = GrdaWarehouse::ServiceHistoryService.
            where(date: start_date..end_date)
          quarter_setup = {}
          setup.each do |k, v|
            quarter_setup[k] = v.merge(shs_scope)
          end
          scope = homeless_scope.with_service_between(
            start_date: start_date,
            end_date: end_date,
            service_scope: shs_scope,
          ).
            joins(:client)
          adult_and_child_scope = scope.where(household_id: adult_and_child_household_ids(start_date, end_date))

          homeless_chart_breakdowns(
            section_title: 'Persons in households with at least one child and one adult',
            charts: charts,
            setup: quarter_setup,
            scope: adult_and_child_scope,
            date: date,
          )
        end
      end
    end

    private def child_only_household_breakdowns
      setup = {
        'Children under 18' => GrdaWarehouse::ServiceHistoryEnrollment.joins(:service_history_services).merge(GrdaWarehouse::ServiceHistoryService.aged(0..17)),
      }
      {}.tap do |charts|
        quarter_dates.each do |date|
          start_date = date.beginning_of_quarter
          end_date = date.end_of_quarter

          shs_scope = GrdaWarehouse::ServiceHistoryService.
            where(date: start_date..end_date)
          quarter_setup = {}
          setup.each do |k, v|
            quarter_setup[k] = v.merge(shs_scope)
          end
          scope = homeless_scope.with_service_between(
            start_date: start_date,
            end_date: end_date,
            service_scope: shs_scope,
          ).
            joins(:client)
          child_only_scope = scope.where(household_id: child_only_household_ids(start_date, end_date))
          homeless_chart_breakdowns(
            section_title: 'Persons in Child-Only Households',
            charts: charts,
            setup: quarter_setup,
            scope: child_only_scope,
            date: date,
          )
        end
      end
    end

    private def gender_breakdowns
      setup = {
        'Female' => GrdaWarehouse::Hud::Client.gender_female,
        'Male' => GrdaWarehouse::Hud::Client.gender_male,
        'Transgender' => GrdaWarehouse::Hud::Client.gender_transgender,
        'No Single Gender' => GrdaWarehouse::Hud::Client.no_single_gender.or(GrdaWarehouse::Hud::Client.questioning),
        'Other or Unknown' => GrdaWarehouse::Hud::Client.gender_unknown,
      }
      {}.tap do |charts|
        quarter_dates.each do |date|
          start_date = date.beginning_of_quarter
          end_date = date.end_of_quarter

          shs_scope = GrdaWarehouse::ServiceHistoryService.
            where(date: start_date..end_date)
          scope = homeless_scope.with_service_between(
            start_date: start_date,
            end_date: end_date,
            service_scope: shs_scope,
          ).
            joins(:client)

          homeless_chart_breakdowns(
            section_title: 'Gender',
            charts: charts,
            setup: setup,
            scope: scope,
            date: date,
          )
        end
      end
    end

    private def race_breakdowns
      setup = {
        'American Indian or Alaska Native' => GrdaWarehouse::Hud::Client.with_races(['AmIndAKNative']),
        'Asian' => GrdaWarehouse::Hud::Client.with_races(['Asian']),
        'Black or African American' => GrdaWarehouse::Hud::Client.with_races(['BlackAfAmerican']),
        'Native Hawaiian or Pacific Islander' => GrdaWarehouse::Hud::Client.with_races(['NativeHIPacific']),
        'White' => GrdaWarehouse::Hud::Client.with_races(['White']),
        'Other or Unknown' => GrdaWarehouse::Hud::Client.with_race_none,
      }
      {}.tap do |charts|
        quarter_dates.each do |date|
          start_date = date.beginning_of_quarter
          end_date = date.end_of_quarter

          shs_scope = GrdaWarehouse::ServiceHistoryService.
            where(date: start_date..end_date)
          scope = homeless_scope.with_service_between(
            start_date: start_date,
            end_date: end_date,
            service_scope: shs_scope,
          ).
            joins(:client)
          homeless_chart_breakdowns(
            section_title: 'Race',
            charts: charts,
            setup: setup,
            scope: scope,
            date: date,
          )
        end
      end
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
        pluck(cl(she_t[:household_id], she_t[:enrollment_group_id]), shs_t[:age], shs_t[:client_id]).
        each do |hh_id, age, client_id|
          next if age.blank? || age.negative?

          key = [hh_id, client_id]
          households[hh_id] ||= []
          households[hh_id] << age unless counted_ids.include?(key)
          counted_ids << key
        end
      households
    end
    memoize :households

    private def adult_and_child_household_ids(start_date, end_date)
      adult_and_child_households = Set.new
      households(start_date, end_date).each do |hh_id, household|
        child_present = household.any? { |age| age < 18 }
        adult_present = household.any? { |age| age >= 18 }
        adult_and_child_households << hh_id if child_present && adult_present
      end
      adult_and_child_households
    end
    memoize :adult_and_child_household_ids

    private def child_only_household_ids(start_date, end_date)
      child_only_households = Set.new
      households(start_date, end_date).each do |hh_id, household|
        child_present = household.any? { |age| age < 18 }
        adult_present = household.any? { |age| age >= 18 }
        child_only_households << hh_id if child_present && ! adult_present
      end
      child_only_households
    end
    memoize :child_only_household_ids

    private def adult_only_household_ids(start_date, end_date)
      adult_only_household_ids = Set.new
      households(start_date, end_date).each do |hh_id, household|
        child_present = household.any? { |age| age < 18 }
        # Include clients of unknown age
        adult_only_household_ids << hh_id unless child_present
      end
      adult_only_household_ids
    end
    memoize :adult_only_household_ids

    private def total_for(scope, population)
      count = scope.select(:client_id).distinct.count
      count = enforce_min_threshold(count, 'min_threshold')

      word = case population
      when :veterans
        'Veteran'
      when :adults_with_children, :hoh_from_adults_with_children
        'Household'
      else
        'Person'
      end

      return pluralize(number_with_delimiter(count), word) if count > 100 || count.zero?

      "less than #{pluralize(100, word)}"
    end

    def map_shapes
      if map_by_zip?
        GrdaWarehouse::Shape.geo_collection_hash(state_zip_shapes)
      elsif map_by_place?
        GrdaWarehouse::Shape.geo_collection_hash(state_place_shapes)
      elsif map_by_county?
        GrdaWarehouse::Shape.geo_collection_hash(state_county_shapes)
      else
        GrdaWarehouse::Shape.geo_collection_hash(state_coc_shapes)
      end
    end

    def map_shape_json
      cache_key = "map-shape-json-#{PublicReports::Setting.first.map_type}-#{ENV['RELEVANT_COC_STATE']}"
      Rails.cache.fetch(cache_key, expires_in: 4.hours) do
        Oj.dump(map_shapes, mode: :compat).html_safe
      end
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

    def state_shape
      GrdaWarehouse::Shape.geo_collection_hash(GrdaWarehouse::Shape::State.my_state)
    end

    def state_shape_json
      cache_key = "state-shape-json-#{ENV['RELEVANT_COC_STATE']}"
      Rails.cache.fetch(cache_key, expires_in: 4.hours) do
        Oj.dump(state_shape, mode: :compat).html_safe
      end
    end

    # COC CODES
    private def geometries
      @geometries ||= GrdaWarehouse::Shape::CoC.where(cocnum: coc_codes)
    end

    private def state_coc_shapes
      @state_coc_shapes ||= GrdaWarehouse::Shape::CoC.my_state
    end

    private def coc_codes
      @coc_codes ||= state_coc_shapes.map(&:cocnum)
    end

    private def population_by_coc
      @population_by_coc ||= {}.tap do |charts|
        quarter_dates.map(&:year).uniq.each do |year|
          charts[year] = {}
          geometries.each do |coc|
            charts[year][coc.cocnum] = coc.population(internal_names: ALL_PEOPLE, year: year).val
          end
        end
      end
    end

    # ZIP CODES
    def map_by_zip?
      PublicReports::Setting.first.map_type == 'zip'
    end

    def map_by_place?
      PublicReports::Setting.first.map_type == 'place'
    end

    def map_by_county?
      PublicReports::Setting.first.map_type == 'county'
    end

    def map_type
      return 'map_zip_js' if map_by_zip?
      return 'map_place_js' if map_by_place?
      return 'map_county_js' if map_by_county?

      'map_js' # CoC
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
      @state_zip_shapes ||= GrdaWarehouse::Shape::ZipCode.my_state
    end

    private def population_by_zip
      @population_by_zip ||= {}.tap do |charts|
        quarter_dates.map(&:year).uniq.each do |year|
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
      @state_county_shapes ||= GrdaWarehouse::Shape::County.my_state
    end

    private def population_by_county
      @population_by_county ||= {}.tap do |charts|
        quarter_dates.map(&:year).uniq.each do |year|
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
      @state_place_shapes ||= GrdaWarehouse::Shape::Town.my_state
    end

    private def population_by_place
      @population_by_place ||= {}.tap do |charts|
        quarter_dates.map(&:year).uniq.each do |year|
          charts[year] = {}
          place_geometries.each do |geo|
            charts[year][geo.name] ||= geo.population(internal_names: ALL_PEOPLE, year: year).val
          end
        end
      end
    end
  end
end
