###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways
  class Report < SimpleReports::ReportInstance
    include Rails.application.routes.url_helpers
    include Queries
    include Reporting::Status

    def run_and_save!
      start
      create_universe
      complete
    end

    def start
      update(started_at: Time.current)
    end

    def complete
      update(completed_at: Time.current)
    end

    def title
      'System Pathways'
    end

    private def filter
      @filter ||= ::Filters::FilterBase.new(
        user_id: user_id,
        enforce_one_year_range: false,
      ).update(options)
    end

    def describe_filter_as_html
      filter.describe_filter_as_html(self.class.report_options)
    end

    # TODO: this will need to be updated when the filter is added
    def self.report_options
      [
        :start,
        :end,
        :project_ids,
        :age_ranges,
      ].freeze
    end

    def url
      system_pathway_warehouse_reports_report_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
    end

    private def create_universe
      enrollment_scope.find_in_batches do |batch|
        report_clients = {}
        batch.each do |processed_enrollment|
          household_id = processed_enrollment.household_id || "#{processed_enrollment.enrollment_group_id}*hh"
          head_of_household = if processed_enrollment.household_id
            processed_enrollment.head_of_household?
          else
            true
          end

          report_client = report_clients[processed_enrollment.client] || HapClient.new(
            client_id: processed_enrollment.client_id,
            first_name: client.first_name,
            last_name: client.last_name,
            personal_ids: client.source_clients.map(&:personal_id).uniq.join('; '),
            age: client.age([@start_date, processed_enrollment.first_date_in_program].max),
            head_of_household: head_of_household,
            household_id: household_id,
            veteran: processed_enrollment.client.veteran?,
          )

          report_clients[client] = report_client
        end
        Client.import(report_clients.values)
        universe.add_universe_members(report_clients)
      end
    end

    def enrollment_scope
      scope = GrdaWarehouse::ServiceHistoryEnrollment.
        entry.
        preload(:client, :enrollment).
        joins(:project).
        open_between(start_date: @filter.start_date, end_date: @filter.end_date)
      filter.apply(scope)
    end
  end
end
