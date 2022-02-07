###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ReportGenerators::DataQuality::Fy2017
  class Q7 < Base
    # ES = [1]
    ES = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:es).flatten(1)
    # SO = [4]
    SO = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:so).flatten(1)

    def run!
      if start_report(Reports::DataQuality::Fy2017::Q7.first)
        @answers = setup_questions()
        @support = @answers.deep_dup
        @clients_with_issues = Set.new
        add_es_so_answers()
        update_report_progress(percent: 50)
        add_es_answers()

        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    def add_es_so_answers
      adult_or_hoh_client_ids = Set.new
      inactive = []
      project_types = ES + SO
      client_ids_for_project_type(project_types).each_slice(250) do |client_ids|
        fetch_night_by_night_clients(project_types, client_ids).each do |client_id, enrollments|
          enrollment = enrollments.last
          entry_date = enrollment[:first_date_in_program]
          exit_date = enrollment[:last_date_in_program]
          if (adult?(enrollment[:age]) || head_of_household?(enrollment[:RelationshipToHoH])) &&
            started_less_than_90_days_before_report(entry_date) &&
            ended_after_report(exit_date)
            adult_or_hoh_client_ids << client_id

            service_dates = [enrollment[:first_date_in_program]]
            service_dates += GrdaWarehouse::ServiceHistoryService.
              where(service_history_enrollment_id: enrollment[:service_history_enrollment_id]).
              order(date: :asc).
              distinct.
              pluck(:date)
            inactive_client = false
            service_dates.each_with_index do |date, index|
              next_date = service_dates[index + 1]
              if next_date.present? && (next_date - date).abs > 90
                inactive_client = true
                next
              end
            end
            inactive << [client_id, enrollment] if inactive_client

          end
        end
      end
      @answers[:q7_b2][:value] = adult_or_hoh_client_ids.size
      @answers[:q7_c2][:value] = inactive.size
      client_personal_ids = personal_ids(inactive.map { |id, _| id })
      @support[:q7_c2][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'Project', 'Entry', 'Exit'],
        data: inactive.map do |id, enrollment|
          [
            id,
            client_personal_ids[id],join(', '),
            enrollment[:project_name],
            enrollment[:first_date_in_program],
            enrollment[:last_date_in_program],
          ]
        end
      )
      @answers[:q7_d2][:value] = ((inactive.size.to_f / adult_or_hoh_client_ids.count) * 100).round(2)
    end

    def add_es_answers
      clients = Set.new
      inactive = []
      project_types = ES
      client_ids_for_project_type(project_types).each_slice(250) do |client_ids|
        fetch_night_by_night_clients(project_types, client_ids).each do |client_id, enrollments|
          enrollment = enrollments.last
          entry_date = enrollment[:first_date_in_program]
          exit_date = enrollment[:last_date_in_program]
          if started_less_than_90_days_before_report(entry_date) && ended_after_report(exit_date)
            clients << client_id
            latest_service_date = GrdaWarehouse::ServiceHistoryService.
              where(service_history_enrollment_id: enrollment[:service_history_enrollment_id]).
              order(date: :asc).
              maximum(:date)

            inactive_client = latest_service_date.blank? || (latest_service_date - @report.options['report_end'].to_date).abs > 90
            inactive << [client_id, enrollment] if inactive_client
          end
        end
      end
      @answers[:q7_b3][:value] = clients.size
      @answers[:q7_c3][:value] = inactive.size
      client_personal_ids = personal_ids(inactive.map { |id, _| id })
      @support[:q7_c3][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'Project', 'Entry', 'Exit'],
        data: inactive.map do |id, enrollment|
          [
            id,
            client_personal_ids[id].join(', '),
            enrollment[:project_name],
            enrollment[:first_date_in_program],
            enrollment[:last_date_in_program],
          ]
        end
      )
      @answers[:q7_d3][:value] = ((inactive.size.to_f / clients.count) * 100).round(2)
    end

    def ended_after_report(exit_date)
      (exit_date.blank? || exit_date > @report.options['report_end'].to_date)
    end

    def started_less_than_90_days_before_report(entry_date)
      entry_date < (@report.options['report_start'].to_date - 90.days)
    end

    def client_batch_scope(project_types)
      active_client_scope.
        hud_project_type(project_types).
        bed_night.
        includes(:enrollment).
        joins(:project).
        distinct
    end

    def client_ids_for_project_type(project_types)
      client_batch_scope(project_types).
        pluck(:client_id)
    end

    def fetch_night_by_night_clients(project_types, client_ids)
      client_batch_scope(project_types).
        where(client_id: client_ids).
        order(first_date_in_program: :asc).
        pluck(*columns.values).
        map do |row|
          Hash[columns.keys.zip(row)]
        end.map do |enrollment|
          enrollment[:age] = age_for_report(dob: enrollment[:DOB], enrollment: enrollment)
          enrollment
        end.group_by do |row|
          row[:client_id]
        end
    end

    def columns
      @columns ||= {
        client_id: she_t[:client_id],
        age: she_t[:age],
        DOB: c_t[:DOB],
        RelationshipToHoH: e_t[:RelationshipToHoH],
        first_date_in_program: she_t[:first_date_in_program],
        last_date_in_program: she_t[:last_date_in_program],
        project_name: she_t[:project_name],
        project_id: she_t[:project_id],
        data_source_id: she_t[:data_source_id],
        enrollment_group_id: she_t[:enrollment_group_id],
        service_history_enrollment_id: she_t[:id],
      }
    end

    def setup_questions
      {
        q7_a1: {
          title:  nil,
          value: 'Data Element',
        },
        q7_b1: {
          title:  nil,
          value: '# of Records',
        },
        q7_c1: {
          title:  nil,
          value: '# of Inactive Records',
        },
        q7_d1: {
          title:  nil,
          value: '% of Inactive Records',
        },
        q7_a2: {
          title:  nil,
          value: 'Contact (Adults and Heads of Household in Street Outreach or ES – NBN)',
        },
        q7_a3: {
          title:  nil,
          value: 'Bed Night (All clients in ES – NBN)',
        },
        q7_b2: {
          title:  'Contact (Adults and Heads of Household in Street Outreach or ES – NBN) - # of Records',
          value: 0,
        },
        q7_c2: {
          title:  'Contact (Adults and Heads of Household in Street Outreach or ES – NBN) - # of Inactive Records',
          value: 0,
        },
        q7_d2: {
          title:  'Contact (Adults and Heads of Household in Street Outreach or ES – NBN) - % of Inactive Records',
          value: 0,
        },
        q7_b3: {
          title:  'Bed Night (All clients in ES – NBN) - # of Records',
          value: 0,
        },
        q7_c3: {
          title:  'Bed Night (All clients in ES – NBN) - # of Inactive Records',
          value: 0,
        },
        q7_d3: {
          title:  'Bed Night (All clients in ES – NBN) - % of Inactive Records',
          value: 0,
        },
      }
    end
  end
end
