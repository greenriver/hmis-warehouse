module ReportGenerators::DataQuality::Fy2016
  class Q4 < Base
    ADULT = 18

    def run!
      if start_report(Reports::DataQuality::Fy2016::Q4.first)
        @answers = setup_questions()
        @support = @answers.deep_dup
        @all_clients = fetch_all_clients()
        update_report_progress(percent: 25)
        @clients_with_issues = Set.new
        add_veteran_answers()

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
        VeteranStatus: :VeteranStatus, 
        enrollment_group_id: :enrollment_group_id, 
        project_id: :project_id, 
        data_source_id: :data_source_id, 
        first_date_in_program: :first_date_in_program,
        last_date_in_program: :last_date_in_program,
        project_name: :project_name,
        destination: :destination,
      }
      
      all_client_scope.
        includes(enrollment: :enrollment_coc_at_entry).
        joins(:project).
        order(date: :asc).
        pluck(*columns.values).
        map do |row|
          Hash[columns.keys.zip(row)]
        end.group_by do |row|
          row[:client_id]
        end
    end

    def add_veteran_answers
      counted = Set.new # Only count each client once
      poor_quality = @all_clients.select do |id, enrollments|
        enrollment = enrollments.last
        age = enrollment[:age]
        veteran_status = enrollment[:VeteranStatus]
        [8,9,99,nil].include?(veteran_status) ||
        (veteran_status == 1 && age.present? && age < ADULT)
      end
      counted += poor_quality.keys
      @clients_with_issues += poor_quality.keys
      @answers[:q3_b2][:value] = poor_quality.size
      @support[:q3_b2][:support] = add_support(
        headers: ['Client ID', 'Vetetan Status', 'Age'],
        data: poor_quality.map do |id, enrollments|
          enrollment = enrollments.last
          [
            id, 
            HUD.no_yes_reasons_for_missing_data(enrollment[:VeteranStatus]),
            enrollment[:age]
          ]
        end
      )
      @answers[:q3_e2][:value] = ((counted.size.to_f / all_client_count) * 100).round(2)
    end

    def setup_questions
      {
        q3_a1: {
          title:  nil,
          value: 'Data Element',
        },
        q3_b1: {
          title:  nil,
          value: 'Error Count',
        },
        q3_c1: {
          title:  nil,
          value: '% of Error Rate',
        },
        q3_a2: {
          title:  nil,
          value: 'Destination (3.12)',
        },
        q3_a3: {
          title:  nil,
          value: 'Income and Sources (4.2) at Entry',
        },
        q3_a4: {
          title:  nil,
          value: 'Income and Sources (4.2) at Annual Assessment',
        },
        q3_a5: {
          title:  nil,
          value: 'Income and Sources (4.2) at Exit',
        },
        q3_b2: {
          title:  'Destination (3.12) - Error Count',
          value: 0,
        },
        q3_c2: {
          title:  'Destination (3.12) - % of Error Rate',
          value: 0,
        },
        q3_b3: {
          title:  'Income and Sources (4.2) at Entry - Error Count',
          value: 0,
        },
        q3_c3: {
          title:  'Income and Sources (4.2) at Entry - % of Error Rate',
          value: 0,
        },
        q3_b4: {
          title:  'Income and Sources (4.2) at Annual Assessment - Error Rate',
          value: 0,
        },
        q3_c4: {
          title:  'Income and Sources (4.2) at Annual Assessment - % of Error Rate',
          value: 0,
        },
        q3_b5: {
          title:  'Income and Sources (4.2) at Exit - Error Rate',
          value: 0,
        },
        q3_c5: {
          title:  'Income and Sources (4.2) at Exit - % of Error Rate',
          value: 0,
        },
      }
    end

  end
end