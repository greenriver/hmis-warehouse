module ReportGenerators::DataQuality::Fy2016
  class Q4 < Base
    ADULT = 18

    def run!
      if start_report(Reports::DataQuality::Fy2016::Q4.first)
        @answers = setup_questions()
        @support = @answers.deep_dup
        @all_clients = fetch_all_clients()
        if @all_clients.any?
          update_report_progress(percent: 25)
          @leavers = calculate_leavers()
          update_report_progress(percent: 50)
          @stayers = calculate_stayers()
          @clients_with_issues = Set.new
          add_destination_answers()
          add_income_at_entry_answers()
        end
        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    def fetch_all_clients
      columns = {
        client_id: :client_id, 
        age: :age, 
        project_type: act_as_project_overlay, 
        project_id: :project_id, 
        data_source_id: :data_source_id,
        first_date_in_program: :first_date_in_program,
        last_date_in_program: :last_date_in_program,
        project_name: :project_name,
        destination: :destination,
      }
      
      all_client_scope.
        includes(:enrollment).
        joins(:project).
        order(date: :asc).
        pluck(*columns.values).
        map do |row|
          Hash[columns.keys.zip(row)]
        end.group_by do |row|
          row[:client_id]
        end
    end

    def add_destination_answers
      counted = Set.new # Only count each client once
      poor_quality = @leavers.select do |_, enrollment|
        [8,9,30,99,nil].include?(enrollment[:destination])
      end
      counted += poor_quality.keys
      @clients_with_issues += poor_quality.keys
      @answers[:q4_b2][:value] = poor_quality.size
      @support[:q4_b2][:support] = add_support(
        headers: ['Client ID', 'Project', 'Entry', 'Exit' 'Destination'],
        data: poor_quality.map do |id, enrollment|
          [
            id, 
            enrollment[:project_name],
            enrollment[:first_date_in_program],
            enrollment[:last_date_in_program],
            HUD.destination(enrollment[:destination]),
          ]
        end
      )
      @answers[:q4_c2][:value] = ((counted.size.to_f / @leavers.count) * 100).round(2)
    end

    def add_income_at_entry_answers
      all_client_scope.includes(enrollment: :income_benefits_at_entry)
    end

    def add_income_annual_update_answers
      all_client_scope.includes(enrollment: :income_benefits_annual_update)
    end

    def add_income_at_exit_answers
      all_client_scope.includes(enrollment: :income_benefits_at_exit)
    end

    def setup_questions
      {
        q4_a1: {
          title:  nil,
          value: 'Data Element',
        },
        q4_b1: {
          title:  nil,
          value: 'Error Count',
        },
        q4_c1: {
          title:  nil,
          value: '% of Error Rate',
        },
        q4_a2: {
          title:  nil,
          value: 'Destination (3.12)',
        },
        q4_a3: {
          title:  nil,
          value: 'Income and Sources (4.2) at Entry',
        },
        q4_a4: {
          title:  nil,
          value: 'Income and Sources (4.2) at Annual Assessment',
        },
        q4_a5: {
          title:  nil,
          value: 'Income and Sources (4.2) at Exit',
        },
        q4_b2: {
          title:  'Destination (3.12) - Error Count',
          value: 0,
        },
        q4_c2: {
          title:  'Destination (3.12) - % of Error Rate',
          value: 0,
        },
        q4_b3: {
          title:  'Income and Sources (4.2) at Entry - Error Count',
          value: 0,
        },
        q4_c3: {
          title:  'Income and Sources (4.2) at Entry - % of Error Rate',
          value: 0,
        },
        q4_b4: {
          title:  'Income and Sources (4.2) at Annual Assessment - Error Rate',
          value: 0,
        },
        q4_c4: {
          title:  'Income and Sources (4.2) at Annual Assessment - % of Error Rate',
          value: 0,
        },
        q4_b5: {
          title:  'Income and Sources (4.2) at Exit - Error Rate',
          value: 0,
        },
        q4_c5: {
          title:  'Income and Sources (4.2) at Exit - % of Error Rate',
          value: 0,
        },
      }
    end

  end
end