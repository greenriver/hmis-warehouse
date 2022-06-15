###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaYyaReport
  class Report < SimpleReports::ReportInstance
    def run_and_save!
      start
      create_universe
      # TODO
      complete
    end

    def start
      update(started_at: Time.current)
    end

    def complete
      update(completed_at: Time.current)
    end

    def title
      'May YYA Report'
    end

    def url
      ma_yya_report_warehouse_reports_report_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
    end

    private def create_universe
      filter = ::Filters::FilterBase.new(
        user_id: user_id,
        enforce_one_year_range: false,
      ).update(options)

      period_size = (filter.end - filter.start).to_i + 1
      previous_period_filter = filter.dup
      previous_period_filter.end = filter.start - 1.day
      previous_period_filter.start = previous_period_filter.start - period_size.days

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
  end
end
