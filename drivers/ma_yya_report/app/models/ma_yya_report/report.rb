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
      # FIXME Look back 1 year to check for previously reported clients
      previous_period_filter = filter.dup
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

    private def calculators
      report_start_date = filter.start
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
      }.freeze
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
