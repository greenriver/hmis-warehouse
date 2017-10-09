module ReportGenerators::CAPER::Fy2017
  # Data Quality: Inactive Records: Street Outreach and Emergency Shelter
  # this is more or less equivalent to the fy2016 data quality question q7
  class Q6f < Base

    ES, SO = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at :es, :so

    def run!
      if start_report(Reports::CAPER::Fy2017::Q6f.first)
        @answers = setup_questions
        @support = @answers.deep_dup
        @clients_with_issues = Set.new

        @es_so_night_by_night_clients = fetch_night_by_night_clients(ES + SO)        
        add_es_so_answers
        update_report_progress percent: 50
        @es_night_by_night_clients = fetch_night_by_night_clients(ES)
        add_es_answers

        finish_report
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    def fetch_night_by_night_clients(project_types)
      columns = columnize(
        # age:                   sh_t, # commented this out as redundant
        client_id:             sh_t, 
        data_source_id:        sh_t,
        enrollment_group_id:   sh_t, 
        first_date_in_program: sh_t,
        last_date_in_program:  sh_t,
        project_id:            sh_t,
        project_name:          sh_t,
        DOB: c_t,
        RelationshipToHoH: e_t,
      )
      
      all_client_scope.
        hud_project_type(project_types).
        bed_night.
        includes(:enrollment).
        joins(:project).
        order(date: :asc).
        pluck(*columns.values).
        map do |row|
          Hash[columns.keys.zip(row)]
        end.each do |enrollment|
          enrollment[:age] = age_for_report(dob: enrollment[:DOB], enrollment: enrollment)
        end.group_by do |row|
          row[:client_id]
        end
    end

    def ended_after_report(exit_date)
      (exit_date.blank? || exit_date > @report.options['report_end'].to_date)
    end

    def started_less_than_90_days_before_report(entry_date)
      entry_date < (@report.options['report_start'].to_date - 90.days)
    end

    def add_es_so_answers
      adult_or_hoh_clients = @es_so_night_by_night_clients.select do |_, (*,enrollment)|
        entry_date = enrollment[:first_date_in_program]
        exit_date = enrollment[:last_date_in_program]
        ( adult?(enrollment) || head_of_household?(enrollment) ) &&
        started_less_than_90_days_before_report(entry_date) &&
        ended_after_report(exit_date)
      end

      @answers[:q6f_b2][:value] = adult_or_hoh_clients.size

      inactive = adult_or_hoh_clients.select do |_, (*,enrollment)|
        service_dates = [enrollment[:first_date_in_program]]
        atts = %i( client_id enrollment_group_id first_date_in_program project_id data_source_id )
        service_dates += GrdaWarehouse::ServiceHistory.service.
          where(
            enrollment.slice :client_id, :enrollment_group_id, :first_date_in_program, :project_id, :data_source_id
          ).
          order(date: :asc).
          distinct.
          pluck(:date)
        service_dates.each_with_index.any? do |date, index|
          next_date = service_dates[index + 1]
          next_date.present? && (next_date - date).abs > 90
        end
      end
      @answers[:q6f_c2][:value] = inactive.size
      @support[:q6f_c2][:support] = add_support(
        headers: ['Client ID', 'Project', 'Entry', 'Exit'],
        data: inactive.map do |_, (*,enrollment)|
          enrollment.values_at :client_id, :project_name, :first_date_in_program, :last_date_in_program
        end
      )
      @answers[:q6f_d2][:value] = ((inactive.size.to_f / adult_or_hoh_clients.count) * 100).round(2)
    end

    def add_es_answers
      clients = @es_so_night_by_night_clients.select do |_, (*,enrollment)|
        entry_date = enrollment[:first_date_in_program]
        exit_date = enrollment[:last_date_in_program]
        started_less_than_90_days_before_report(entry_date) &&
        ended_after_report(exit_date)
      end
      @answers[:q6f_b3][:value] = clients.size

      inactive = clients.select do |_, (*,enrollment)|
        latest_service_date = GrdaWarehouse::ServiceHistory.service.
          where(
            enrollment.slice :client_id, :enrollment_group_id, :first_date_in_program, :project_id, :data_source_id
          ).
          order(date: :asc).
          maximum(:date)
        latest_service_date.blank? || (latest_service_date - @report.options['report_end'].to_date).abs > 90
      end
      @answers[:q6f_c3][:value] = inactive.size
      @support[:q6f_c3][:support] = add_support(
        headers: ['Client ID', 'Project', 'Entry', 'Exit'],
        data: inactive.map do |id, (*,enrollment)|
          enrollment.values_at :client_id, :project_name, :first_date_in_program, :last_date_in_program
        end
      )
      @answers[:q6f_d3][:value] = ((inactive.size.to_f / clients.count) * 100).round(2)
    end

    def setup_questions
      {
        q6f_a1: {
          title:  nil,
          value: 'Data Element',
        },
        q6f_b1: {
          title:  nil,
          value: '# of Records',
        },
        q6f_c1: {
          title:  nil,
          value: '# of Inactive Records',
        },
        q6f_d1: {
          title:  nil,
          value: '% of Inactive Records',
        },
        q6f_a2: {
          title:  nil,
          value: 'Contact (Adults and Heads of Household in Street Outreach or ES – NBN)',
        },
        q6f_a3: {
          title:  nil,
          value: 'Bed Night (All clients in ES – NBN)',
        },
        q6f_b2: {
          title:  'Contact (Adults and Heads of Household in Street Outreach or ES – NBN) - # of Records',
          value: 0,
        },
        q6f_c2: {
          title:  'Contact (Adults and Heads of Household in Street Outreach or ES – NBN) - # of Inactive Records',
          value: 0,
        },
        q6f_d2: {
          title:  'Contact (Adults and Heads of Household in Street Outreach or ES – NBN) - % of Inactive Records',
          value: 0,
        },
        q6f_b3: {
          title:  'Bed Night (All clients in ES – NBN) - # of Records',
          value: 0,
        },
        q6f_c3: {
          title:  'Bed Night (All clients in ES – NBN) - # of Inactive Records',
          value: 0,
        },
        q6f_d3: {
          title:  'Bed Night (All clients in ES – NBN) - % of Inactive Records',
          value: 0,
        },        
      }
    end

  end
end