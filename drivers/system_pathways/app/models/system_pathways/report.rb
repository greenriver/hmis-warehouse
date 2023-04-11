###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways
  class Report < SimpleReports::ReportInstance
    include Rails.application.routes.url_helpers
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
      system_pathways_warehouse_reports_report_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
    end

    private def create_universe
      client_ids.each_slice(250) do |ids|
        enrollment_scope.where(client_ids: ids) do |batch|
          # TODO: group by client_id so we can determine which enrollments to use
          # for system pathway
          report_clients = {}
          batch.each do |processed_enrollment|
            household_id = processed_enrollment.household_id || "#{processed_enrollment.enrollment_group_id}*hh"
            head_of_household = if processed_enrollment.household_id
              processed_enrollment.head_of_household?
            else
              true
            end

            report_client = report_clients[processed_enrollment.client] || Client.new(
              client_id: processed_enrollment.client_id,
              first_name: client.first_name,
              last_name: client.last_name,
              personal_ids: client.source_clients.map(&:personal_id).uniq.join('; '),
              age: client.age([@start_date, processed_enrollment.first_date_in_program].max),
              head_of_household: head_of_household,
              household_id: household_id,
              veteran: processed_enrollment.client.veteran?,
              # TODO: categorize the exit destination for the final enrollment
              # destination_homeless
              # destination_temporary
              # destination_institutional
              # destination_other
              # destination_permanent
              # TODO: If the client returned to homelessness after exiting to a permanent
              # destination, collect the information about the return enrollment
              # returned_project_type
              # returned_project_name
              # returned_project_entry_date
              # returned_project_enrollment_id
              # returned_project_project_id
            )

            report_clients[client] = report_client
          end
          Client.import(report_clients.values)
          # TODO: we'll need to get the client IDs to associate them with the enrollments (or maybe we should use the destination client id)
          # We'll need to add enrollments for each bucket
          # client
          # from_project_type - should be null if this is the first enrollment
          # project
          # enrollment
          # project_type
          # destination - should be null unless this is the last enrollment
          # project_name
          # entry_date
          # exit_date
          # stay_length
          # TODO: scopes for each section should look something like
          # system->ES: client.joins(:enrollments).where enrollments.from_project_type is null
          #   and project_type = 1
          # ES->Permanent Destination: client.where(destination_permanent: true).joins(:enrollments).where enrollments.project_type = 1
          #   and destination is not null
          universe.add_universe_members(report_clients)
        end
      end
    end

    private def client_ids
      @client_ids ||= enrollment_scope.distinct.pluck(:client_id)
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
