###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaYyaReport
  class Report < SimpleReports::ReportInstance
    include Rails.application.routes.url_helpers
    include Reporting::Status

    def run_and_save!
      start
      create_universe
      report_results
      complete
    end

    def start
      update(started_at: Time.current)
    end

    def complete
      update(completed_at: Time.current)
    end

    def title
      'MA YYA Report'
    end

    def url
      ma_yya_report_warehouse_reports_report_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
    end

    private def create_universe
      previous_period_filter = filter.deep_dup
      previous_period_filter.end = filter.start - 1.day
      previous_period_filter.start = previous_period_filter.start - 1.year

      previous_period_calculator = UniverseCalculator.new(previous_period_filter)
      previous_period_clients = previous_period_calculator.client_ids

      universe_calculator = UniverseCalculator.new(filter)
      universe_calculator.calculate do |clients|
        clients.transform_values do |client|
          client[:reported_previous_period] = previous_period_clients.include?(client[:client_id])
        end

        Client.import(clients.values)
        universe.add_universe_members(clients)
      end
    end

    private def filter
      @filter ||= ::Filters::FilterBase.new(
        user_id: user_id,
        enforce_one_year_range: false,
      ).update(options)
    end

    private def a_t
      MaYyaReport::Client.arel_table
    end

    private def calculators # rubocop:disable Metrics/AbcSize
      report_start_date = filter.start
      report_end_date = filter.end

      f2_population = a_t[:reported_previous_period].eq(false).and(a_t[:currently_homeless].eq(true))
      g_population = a_t[:reported_previous_period].eq(false).and(
        a_t[:at_risk_of_homelessness].eq(true).
          and(Arel.sql(
                json_contains(:subsequent_current_living_situations,
                              [15, 6, 7, 25, 4, 5, 29, 14, 32, 36, 35, 28, 19, 3, 31, 33, 34, 10, 20, 21, 11]),
              )).
          or(a_t[:currently_homeless].eq(true).and(a_t[:rehoused_on].between(report_start_date..report_end_date)).
            and(a_t[:subsequent_current_living_situations].not_eq('[]'))),
      )

      {
        A1a: a_t[:currently_homeless].eq(true),
        A1b: a_t[:at_risk_of_homelessness].eq(true),

        A2a: a_t[:initial_contact].eq(true).and(a_t[:currently_homeless].eq(true)),
        A2b: a_t[:initial_contact].eq(true).and(a_t[:at_risk_of_homelessness].eq(true)),

        A3a: a_t[:entry_date].gteq(report_start_date).and(a_t[:at_risk_of_homelessness].eq(true)),
        A3b: a_t[:entry_date].lt(report_start_date).and(a_t[:at_risk_of_homelessness].eq(true)),
        A3c: nil, # Non-HMIS queries should be nil

        A4a: a_t[:entry_date].gteq(report_start_date).and(a_t[:currently_homeless].eq(true)),
        A4b: a_t[:entry_date].lt(report_start_date).and(a_t[:currently_homeless].eq(true)),
        A4c: nil,

        A5a: a_t[:direct_assistance].eq(true),
        A5b: nil,
        A5c: nil,
        A5d: nil,
        A5e: nil,
        A5f: nil,
        A5g: nil,
        A5h: nil,
        A5i: nil,
        A5j: nil,
        A5k: nil,
        A5l: nil,
        A5m: nil,
        A5n: nil,

        TotalYYAServed: a_t[:currently_homeless].eq(true).or(a_t[:at_risk_of_homelessness].eq(true)),

        C1: nil,
        C3: nil,
        TotalCollegeStudentsServed: a_t[:education_status_date].lteq(report_end_date).
          and(a_t[:current_school_attendance].in([1, 2])).and(a_t[:current_educational_status].in([1, 2, 3, 4])),

        D1a: a_t[:age].lt(18),
        D1b: a_t[:gender].eq(1),
        D1c: a_t[:gender].eq(0),
        D1d: a_t[:gender].eq(5),
        D1e: a_t[:gender].in([4, 6, 8, 9, 99]),

        D2a: a_t[:race].eq(5),
        D2b: a_t[:race].eq(3),
        D2c: a_t[:race].eq(2),
        D2d: a_t[:race].eq(1),
        D2e: a_t[:race].eq(4),
        D2f: a_t[:race].in([6, 8, 9, 99]),
        D2g: a_t[:ethnicity].eq(1),
        D2h: nil,
        D2i: nil,
        D2j: nil,

        D3a: a_t[:mental_health_disorder].eq(true),
        D3b: a_t[:substance_use_disorder].eq(true),
        D3c: a_t[:physical_disability].eq(true),
        D3d: a_t[:developmental_disability].eq(true),

        D4a: a_t[:pregnant].eq(1).and(a_t[:due_date].gt(report_start_date)).
          or(a_t[:head_of_household].eq(true).and(Arel.sql(custodial_parent_query))),
        D4b: a_t[:sexual_orientation].in([2, 3, 4, 5]).or(a_t[:gender].eq(5)),
        D4c: a_t[:education_status_date].lteq(report_end_date).
          and(a_t[:current_school_attendance].eq(0)).and(a_t[:most_recent_education_status].in([0, 1])),
        D4d: a_t[:health_insurance].eq(true),

        Ea: nil,
        Eb: nil,

        F1a: a_t[:subsequent_current_living_situations].not_eq('[]').and(a_t[:reported_previous_period].eq(false)),
        F1b: a_t[:reported_previous_period].eq(false).
          and(Arel.sql(
                json_contains(:subsequent_current_living_situations,
                              [15, 6, 7, 25, 4, 5, 29, 14, 32, 36, 35, 28, 19, 3, 31, 33, 34, 10, 20, 21, 11]),
              )),

        F2a: f2_population.
          and(a_t[:rehoused_on].between(report_start_date..report_end_date)),
        F2b: f2_population.
          and(a_t[:rehoused_on].between(report_start_date..report_end_date)).
          and(a_t[:subsequent_current_living_situations].not_eq('[]')),
        F2c: f2_population.
          and(a_t[:rehoused_on].not_eq(nil)).
          and(Arel.sql(json_contains(:subsequent_current_living_situations, [19, 3, 31, 33, 34, 10, 20, 21, 11]))),
        F2d: nil,

        G1a: g_population.and(a_t[:age].lt(18)),
        G1b: g_population.and(a_t[:gender].eq(1)),
        G1c: g_population.and(a_t[:gender].eq(0)),
        G1d: g_population.and(a_t[:gender].eq(5)),
        G1e: g_population.and(a_t[:gender].in([4, 6, 8, 9, 99])),

        G2a: g_population.and(a_t[:race].eq(5)),
        G2b: g_population.and(a_t[:race].eq(3)),
        G2c: g_population.and(a_t[:race].eq(2)),
        G2d: g_population.and(a_t[:race].eq(1)),
        G2e: g_population.and(a_t[:race].eq(4)),
        G2f: g_population.and(a_t[:race].in([6, 8, 9, 99])),
        G2g: g_population.and(a_t[:ethnicity].eq(1)),

        G3a: g_population.and(a_t[:sexual_orientation].in([2, 3, 4, 5]).or(a_t[:gender].eq(5))),
      }.freeze
    end

    private def custodial_parent_query
      'jsonb_array_length(household_ages) > 1' +
        'AND EXISTS(SELECT jsonb_array_elements(household_ages) AS age WHERE age < 18)'
    end

    private def json_contains(field, contents)
      contents.map { |val| "#{field} @> '#{val}'" }.join(' OR ')
    end

    private def report_results
      calculators.each do |cell_name, query|
        cell = report_cells.create(name: cell_name)
        next if query.nil? # Create a cell for a Non-HMIS query, but leave it blank

        clients = universe.members.where(query)
        cell.add_members(clients)
        cell.update!(summary: clients.count)
      end
    end

    def labels
      calculators.keys
    end

    def cell(cell_name)
      report_cells.find_by(name: cell_name)
    end

    def answer(cell_name)
      cell(cell_name)&.summary
    end

    def self.yya_projects(user)
      GrdaWarehouse::Hud::Project.options_for_select(user: user)
    end

    def self.report_options
      [
        :start,
        :end,
        :project_ids,
      ].freeze
    end
  end
end
