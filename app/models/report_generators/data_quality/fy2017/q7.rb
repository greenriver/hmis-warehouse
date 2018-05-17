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
        @es_so_night_by_night_clients = fetch_night_by_night_clients(ES + SO)        
        add_es_so_answers()

        update_report_progress(percent: 50)
        @es_night_by_night_clients = fetch_night_by_night_clients(ES)
        add_es_answers()

        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    def add_es_so_answers
      adult_or_hoh_clients = @es_so_night_by_night_clients.select do |_, enrollments|
        enrollment = enrollments.last
        entry_date = enrollment[:first_date_in_program]
        exit_date = enrollment[:last_date_in_program]
        (adult?(enrollment[:age]) || head_of_household?(enrollment[:RelationshipToHoH])) &&
        started_less_than_90_days_before_report(entry_date) &&
        ended_after_report(exit_date)
        
      end
      @answers[:q7_b2][:value] = adult_or_hoh_clients.size

      inactive = adult_or_hoh_clients.select do |_, enrollments|
        enrollment = enrollments.last
        service_dates = [enrollment[:first_date_in_program]]
        service_dates += GrdaWarehouse::ServiceHistory.service.
          where(
            client_id: enrollment[:client_id],
            enrollment_group_id: enrollment[:enrollment_group_id],
            first_date_in_program: enrollment[:first_date_in_program],
            project_id: enrollment[:project_id],
            data_source_id: enrollment[:data_source_id],
          ).
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
        inactive_client
      end
      @answers[:q7_c2][:value] = inactive.size
      @support[:q7_c2][:support] = add_support(
        headers: ['Client ID', 'Project', 'Entry', 'Exit'],
        data: inactive.map do |id, enrollments|
          enrollment = enrollments.last
          [
            id, 
            enrollment[:project_name],
            enrollment[:first_date_in_program],
            enrollment[:last_date_in_program],
          ]
        end
      )
      @answers[:q7_d2][:value] = ((inactive.size.to_f / adult_or_hoh_clients.count) * 100).round(2)
    end

    def add_es_answers
      clients = @es_so_night_by_night_clients.select do |_, enrollments|
        enrollment = enrollments.last
        entry_date = enrollment[:first_date_in_program]
        exit_date = enrollment[:last_date_in_program]
        started_less_than_90_days_before_report(entry_date) &&
        ended_after_report(exit_date)
      end
      @answers[:q7_b3][:value] = clients.size

      inactive = clients.select do |_, enrollments|
        enrollment = enrollments.last

        latest_service_date = GrdaWarehouse::ServiceHistory.service.
          where(
            client_id: enrollment[:client_id],
            enrollment_group_id: enrollment[:enrollment_group_id],
            first_date_in_program: enrollment[:first_date_in_program],
            project_id: enrollment[:project_id],
            data_source_id: enrollment[:data_source_id],
          ).
          order(date: :asc).
          maximum(:date)
        latest_service_date.blank? || (latest_service_date - @report.options['report_end'].to_date).abs > 90
      end
      @answers[:q7_c3][:value] = inactive.size
      @support[:q7_c3][:support] = add_support(
        headers: ['Client ID', 'Project', 'Entry', 'Exit'],
        data: inactive.map do |id, enrollments|
          enrollment = enrollments.last
          [
            id, 
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

    def fetch_night_by_night_clients(project_types)
      columns = {
        client_id: she_t[:client_id].to_sql, 
        age: she_t[:age].to_sql,
        DOB: c_t[:DOB].to_sql,
        RelationshipToHoH: e_t[:RelationshipToHoH].to_sql,
        first_date_in_program: she_t[:first_date_in_program].to_sql,
        last_date_in_program: she_t[:last_date_in_program].to_sql,
        project_name: she_t[:project_name].to_sql,
        project_id: she_t[:project_id].to_sql,
        data_source_id: she_t[:data_source_id].to_sql,
        enrollment_group_id: she_t[:enrollment_group_id].to_sql, 
      }
      
      all_client_scope.
        hud_project_type(project_types).
        bed_night.
        includes(:enrollment).
        joins(:project).
        order(date: :asc).
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