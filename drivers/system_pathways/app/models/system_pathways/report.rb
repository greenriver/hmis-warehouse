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

    private def allowed_states
      {
        nil => [1, 2, 3, 4, 8, 9, 10, 13],
        1 => [2, 3, 9, 10, 13],
        2 => [3, 9, 10, 13],
        3 => [],
        4 => [2, 3, 9, 10, 13],
        8 => [2, 3, 9, 10, 13],
        9 => [],
        10 => [],
        13 => [3, 9, 10],
      }
    end

    private def accept_enrollments(subsequent_enrollments, current_project_type = nil, accepted_enrollments = [])
      return accepted_enrollments if subsequent_enrollments.blank?

      enrollment = subsequent_enrollments.first
      if enrollment.exit_date.blank? || HudUtility.destination_type(enrollment.destination) == 'Permanent'
        accepted_enrollments << enrollment
        return accepted_enrollments
      end

      if allowed_states[current_project_type].include?(enrollment.computed_project_type)
        accepted_enrollments << enrollment
        accept_enrollments(subsequent_enrollments.drop(1), enrollment.computed_project_type, accepted_enrollments)
      else
        accept_enrollments(subsequent_enrollments.drop(1), current_project_type, accepted_enrollments)
      end
    end

    private def create_universe
      client_ids.each_slice(250) do |ids|
        enrollment_scope.where(client_ids: ids) do |enrollment_batch|
          report_clients = {}
          report_enrollments = []
          enrollment_batch.group_by(&:client).each do |client, enrollments|
            served_by_ce = enrollments.any?(:ce?)
            involved_enrollments = enrollments.
              reject(:ce?). # remove CE, we only use it for filtering
              # move the most-recently exited or open enrollments to the end
              sort_by { |a, b| a.exit_date || Date.tomorrow <=> b.exit_date || Date.tomorrow }.
              group_by(&:computed_project_type).
              # keep only the last enrollment in each category
              transform_values(&:last).
              values

            accepted_enrollments = accept_enrollments(involved_enrollments)
            final_enrollment = accepted_enrollments.last
            returned_enrollment = enrollments.detect do |en|
              next false if final_enrollment.exit_date.blank? || ! HudUtility.destination_type(final_enrollment.destination) == 'Permanent'

              en.homeless?
            end

            report_client = report_clients[client] || Client.new(
              client_id: client.id,
              first_name: client.first_name,
              last_name: client.last_name,
              personal_ids: client.source_clients.map(&:personal_id).uniq.join('; '),
              dob: client.dob,
              age: client.age(@start_date),
              am_ind_ak_native: client.am_ind_ak_native == 1,
              asian: client.asian == 1,
              black_af_american: client.black_af_american == 1,
              native_hi_pacific: client.native_hi_pacific == 1,
              white: client.white == 1,
              ethnicity: client.ethnicity,
              male: client.male == 1,
              female: client.female == 1,
              transgender: client.transgender == 1,
              questioning: client.questioning == 1,
              no_single_gender: client.no_single_gender == 1,
              veteran_status: client.veteran_status,
              ce: served_by_ce,
              destination: final_enrollment.destination,
              destination_homeless: HudUtility.destination_type(final_enrollment.destination) == 'Homeless',
              destination_temporary: HudUtility.destination_type(final_enrollment.destination) == 'Temporary',
              destination_institutional: HudUtility.destination_type(final_enrollment.destination) == 'Institutional',
              destination_other: HudUtility.destination_type(final_enrollment.destination) == 'Other',
              destination_permanent: HudUtility.destination_type(final_enrollment.destination) == 'Permanent',
              returned_project_type: returned_enrollment&.computed_project_type,
              returned_project_name: returned_enrollment&.project&.name,
              returned_project_entry_date: returned_enrollment&.entry_date,
              returned_project_enrollment_id: returned_enrollment&.enrollment&.enrollment_id,
              returned_project_project_id: returned_enrollment&.project_id,
            )
            report_clients[client] = report_client

            accepted_enrollments.each.with_index do |en, i|
              from_project_type = nil
              from_project_type = accepted_enrollments[i - 1].computed_project_type if i.positive?
              stay_length = (en.entry_date .. [en.exit_date, filter.end].compact.min).count
              household_id = en.household_id || "#{en.enrollment_group_id}*hh"

              report_enrollments << Enrollment.new(
                client_id: client.id,
                from_project_type: from_project_type,
                project_id: en.project_id,
                enrollment_id: en.enrollment&.enrollment_id,
                project_type: en.computed_project_type,
                destination: en.destination,
                project_name: en.project.name,
                entry_date: en.entry_date,
                exit_date: en.exit_date,
                stay_length: stay_length,
                disabling_condition: en.enrollment.disabling_condition,
                relationship_to_hoh: en.enrollment.relationship_to_hoh,
                household_id: household_id,
                # FIXME: need to use HUD household calculation
                # household_type: household_type,
              )
            end
          end
          Client.import(report_clients.values)
          Enrollment.import(report_enrollments)
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
        in_project_type([1, 2, 3, 4, 8, 9, 10, 13, 14]).
        preload(:client, :enrollment).
        joins(:project).
        open_between(start_date: filter.start_date, end_date: filter.end_date)
      filter.apply(scope)
    end
  end
end
