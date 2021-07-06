###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
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

    MIN_THRESHOLD = 10

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

    def publish!(content)
      unless published?
        # This should:
        # 1. Take the contents of html and push it up to S3
        # 2. Populate the published_url field
        # 3. Populate the embed_code field
        self.class.transaction do
          unpublish_similar
          update(
            html: content,
            published_url: generate_publish_url, # NOTE this isn't used in this report
            embed_code: generate_embed_code, # NOTE this isn't used in this report
            state: :published,
          )
        end
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
        )
        if resp.etag
          Rails.logger.info 'Successfully uploaded report file to s3'
        else
          Rails.logger.info 'Unable to upload report file'
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
      "<iframe width='500' height='400' src='#{generate_publish_url_for(section)}' frameborder='0' sandbox><a href='#{generate_publish_url_for(section)}'>#{instance_title} -- #{section.to_s.humanize}</a></iframe>"
    end

    def sections
      [
        :pit,
        :summary,
        :map,
        :who,
        :raw,
      ].freeze
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
        pit_chart: pit_chart,
        inflow_outflow: inflow_outflow,
        location_chart: location_chart,
        household_type: household_type,
        race_chart: race_chart,
        need_map: need_map,
        homeless_breakdowns: homeless_breakdowns,
      }.to_json
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

    def map_shapes
      GrdaWarehouse::Shape.geo_collection_hash(state_coc_shapes)
    end

    private def state_coc_shapes
      GrdaWarehouse::Shape::CoC.my_state
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

    private def pit_chart
      x = ['x']
      y = ['People served in ES, SO, SH, or TH']
      pit_counts.each do |date, count|
        x << date
        y << count
      end
      [x, y].to_json
    end

    private def inflow_outflow
      x = ['x']
      ins = ['People entering ES, SO, SH, or TH (first time homeless)']
      outs = ['People exiting ES, SO, SH, or TH to a permanent destination']
      inflow_out_flow_counts.each do |date, in_count, out_count|
        x << date
        ins << in_count
        outs << out_count
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
          sheltered = scope.homeless_sheltered.select(:client_id).distinct

          unsheltered = scope.homeless_unsheltered.select(:client_id).distinct
          charts[:all_homeless][date.iso8601] = {
            data: [
              ['Sheltered', sheltered.count],
              ['Unsheltered', unsheltered.count],
            ],
            total: total_for(scope, nil),
          }
          charts[:homeless_veterans][date.iso8601] = {
            data: [
              ['Sheltered', sheltered.veteran.count],
              ['Unsheltered', unsheltered.veteran.count],
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

          total = adult_only_household_ids(start_date, end_date).count + adult_and_child_household_ids(start_date, end_date).count + child_only_household_ids(start_date, end_date).count
          charts[date.iso8601] = {
            data: [
              ['Adult Only', adult_only_household_ids(start_date, end_date).count],
              ['Adults with Children', adult_and_child_household_ids(start_date, end_date).count],
              ['Children-Only Households', child_only_household_ids(start_date, end_date).count],
            ],
            total: pluralize(number_with_delimiter(total), 'Household'),
          }
        end
      end
    end

    private def race_chart
      {}.tap do |charts|
        quarter_dates.each do |date|
          start_date = date.beginning_of_quarter
          end_date = date.end_of_quarter
          client_ids = Set.new
          client_cache = GrdaWarehouse::Hud::Client.new
          data = {}
          census_data = {}
          # Add census info
          ::HUD.races(multi_racial: true).each do |race_code, label|
            census_data[label] = 0
            data[::HUD.race(race_code, multi_racial: true)] ||= Set.new
            year = date.year
            full_pop = get_us_census_population(year: year) || 0
            race_pop = get_us_census_population(race_code: race_code, year: year) || 0
            census_data[label] = race_pop / full_pop.to_f if full_pop.positive?
          end

          scope = homeless_scope.with_service_between(
            start_date: start_date,
            end_date: end_date,
          )
          all_destination_ids = scope.distinct.pluck(:client_id)
          scope.joins(:client).preload(:client).
            order(first_date_in_program: :desc). # Use the newest start
            find_each do |enrollment|
              client = enrollment.client
              race = client_cache.race_string(destination_id: client.id, scope_limit: client.class.where(id: all_destination_ids))
              data[::HUD.race(race, multi_racial: true)] << client.id unless client_ids.include?(client.id)
              client_ids << client.id
            end
          total_count = data.map { |_, ids| ids.count }.sum
          # Format:
          # [["Black or African American",38, 53],["White",53, 76],["Native Hawaiian or Other Pacific Islander",1, 12],["Multi-Racial",4, 10],["Asian",1, 5],["American Indian or Alaska Native",1, 1]]
          combined_data = data.map do |race, ids|
            label = if race == 'None'
              'Unknown'
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

    # Counts and rate of homeless individuals by CoC
    private def homeless_map
      census_comparison(homeless_scope)
    end

    private def youth_homeless_map
      @filter = filter_object.deep_dup
      @filter.age_ranges = [:eighteen_to_twenty_four]
      scope = filter_for_age(homeless_scope)
      census_comparison(scope)
    end

    private def adults_homeless_map
      scope = homeless_scope.adult_only_households
      census_comparison(scope)
    end

    private def adults_with_children_homeless_map
      scope = homeless_scope.adults_with_children
      census_comparison(scope)
    end

    private def veterans_homeless_map
      scope = homeless_scope.veterans
      census_comparison(scope)
    end

    private def census_comparison(scope)
      {}.tap do |charts|
        quarter_dates.each do |date|
          start_date = date.beginning_of_quarter
          end_date = date.end_of_quarter
          charts[date.iso8601] = {}
          coc_codes.each do |coc_code|
            population_overall = population_by_coc[date.year][coc_code]
            count = if Rails.env.production?
              scope.with_service_between(
                start_date: start_date,
                end_date: end_date,
              ).in_coc(coc_code: coc_code).count
            else
              max = [population_overall, 1].compact.max / 10_000
              (0..max).to_a.sample
            end
            count = 10 if count < 10
            # rate per 10,000
            rate = count / population_overall.to_f * 10_000.0
            charts[date.iso8601][coc_code] = {
              count: count,
              overall_population: population_overall.to_i,
              rate: rate.round(1),
            }
          end
        end
      end
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
      ch_t = GrdaWarehouse::HudChronic.arel_table
      chronic_date = GrdaWarehouse::HudChronic.where(ch_t[:date].lteq(end_date)).maximum(:date)
      chronic_scope = GrdaWarehouse::HudChronic.where(date: chronic_date)
      setup.each do |title, client_scope|
        chronic_count = chronic_scope.where(client_id: scope.merge(client_scope).select(:client_id)).count
        sheltered_count = scope.homeless_sheltered.merge(client_scope).select(:client_id).distinct.count
        sheltered_count = enforce_min_threshold(sheltered_count)
        unsheltered_count =scope.homeless_unsheltered.merge(client_scope).select(:client_id).distinct.count
        unsheltered_count = enforce_min_threshold(unsheltered_count)
        charts[section_title] ||= {
          'sub_sections' => {},
          'chronic_counts' => {},
          'total_counts' => {},
          'chronic_percents' => {},
        }
        intermediate_chronic_count ||= 0
        intermediate_total_count ||= 0

        total_string = total_for(scope.merge(client_scope), nil)
        total_count = scope.merge(client_scope).distinct.select(:client_id).count

        intermediate_chronic_count += chronic_count
        intermediate_total_count += total_count

        charts[section_title]['chronic_counts'][date.iso8601] = intermediate_chronic_count
        charts[section_title]['chronic_counts'][date.iso8601] = enforce_min_threshold(charts[section_title]['chronic_counts'][date.iso8601])
        charts[section_title]['total_counts'][date.iso8601] = intermediate_total_count
        charts[section_title]['chronic_percents'][date.iso8601] ||= 0
        charts[section_title]['chronic_percents'][date.iso8601] = (intermediate_chronic_count.to_f / intermediate_total_count * 100).round if intermediate_total_count.positive?
        charts[section_title]['sub_sections'][title] ||= {}
        charts[section_title]['sub_sections'][title][date.iso8601] = {
          total: total_string,
          data: [
            ['Sheltered', sheltered_count],
            ['Unsheltered', unsheltered_count],
          ],
          categories: [ title ],
        }
      end
    end

    private def enforce_min_threshold(count)
      return 0 if count.blank? || count.zero?
      return 10 if count < MIN_THRESHOLD

      count
    end

    private def adult_only_household_breakdowns
      setup = {
        'Persons Age 18 to 24' => GrdaWarehouse::ServiceHistoryEnrollment.where(age: 18..24),
        'Persons over age 24' => GrdaWarehouse::ServiceHistoryEnrollment.where(age: 24..105),
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
          ).joins(:client)
          adult_only_scope = scope.where(household_id: adult_only_household_ids(start_date, end_date))

          homeless_chart_breakdowns(
            section_title: 'Persons in Households Without Children',
            charts: charts,
            setup: setup,
            scope: adult_only_scope,
            date: date,
          )
        end
      end
    end

    private def adult_and_child_household_breakdowns
      setup = {
        'Children under 18' => GrdaWarehouse::ServiceHistoryEnrollment.where(age: 0..17),
        'Persons Age 18 to 24' => GrdaWarehouse::ServiceHistoryEnrollment.where(age: 18..24),
        'Persons over age 24' => GrdaWarehouse::ServiceHistoryEnrollment.where(age: 24..105),
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
          ).joins(:client)
          adult_and_child_scope = scope.where(household_id: adult_and_child_household_ids(start_date, end_date))

          homeless_chart_breakdowns(
            section_title: 'Persons in households with at least one child and one adult',
            charts: charts,
            setup: setup,
            scope: adult_and_child_scope,
            date: date,
          )
        end
      end
    end

    private def child_only_household_breakdowns
      setup = {
        'Children under 18' => GrdaWarehouse::ServiceHistoryEnrollment.where(age: 0..17),
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
          ).joins(:client)
          child_only_scope = scope.where(household_id: child_only_household_ids(start_date, end_date))
          homeless_chart_breakdowns(
            section_title: 'Persons in Households Without Children',
            charts: charts,
            setup: setup,
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
        'Gender non-conforming' => GrdaWarehouse::Hud::Client.gender_non_conforming,
        'Unknown' => GrdaWarehouse::Hud::Client.gender_unknown,
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
          ).joins(:client)

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
        'Native Hawaiian or Other Pacific Islander' => GrdaWarehouse::Hud::Client.with_races(['NativeHIOtherPacific']),
        'White' => GrdaWarehouse::Hud::Client.with_races(['White']),
        'Multi-Racial' => GrdaWarehouse::Hud::Client.multi_racial,
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
          ).joins(:client)
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
      count = 10 if count.positive? && count < 10

      word = case population
      when :veterans
        'Veteran'
      when :adults_with_children, :hoh_from_adults_with_children
        'Household'
      else
        'Person'
      end

      pluralize(number_with_delimiter(count), word)
    end

    private def get_us_census_population(race_code: 'All', year:)
      race_var = \
        case race_code
        when 'AmIndAKNative' then NATIVE_AMERICAN
        when 'Asian' then ASIAN
        when 'BlackAfAmerican' then BLACK
        when 'NativeHIOtherPacific' then PACIFIC_ISLANDER
        when 'White' then WHITE
        when 'RaceNone' then OTHER_RACE
        when 'MultiRacial' then TWO_OR_MORE_RACES
        when 'All' then ALL_PEOPLE
        else
          raise "Invalid race code: #{race_code}"
        end

      results = geometries.map do |coc|
        coc.population(internal_names: race_var, year: year)
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

    private def geometries
      @geometries ||= GrdaWarehouse::Shape::CoC.where(cocnum: coc_codes)
    end

    private def coc_codes
      @coc_codes ||= GrdaWarehouse::Shape::CoC.my_state.map(&:cocnum)
    end
  end
end
