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

    def run_and_save!
      start_report
      pre_calculate_data
      complete_report
    end

    def view_template
      populations.keys
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
        # overall_homeless_map: overall_homeless_map,
        # population_homeless_maps: population_homeless_maps,

        # race_chart: race_chart,
        # housing_status_breakdowns: housing_status_breakdowns,
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
      scope = filter_for_range(report_scope)

      @coc_codes ||= begin
        result = scope.joins(project: :project_cocs).distinct.
          pluck(pc_t[:hud_coc_code], pc_t[:CoCCode]).map do |override, original|
            override.presence || original
          end
        reasonable_cocs_count = GrdaWarehouse::Shape::CoC.my_state.where(cocnum: result).count
        result = GrdaWarehouse::Shape::CoC.my_state.map(&:cocnum) if reasonable_cocs_count.zero? && !Rails.env.production?

        result
      end
    end
  end
end
