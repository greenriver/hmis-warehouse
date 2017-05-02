module ReportGenerators::DataQuality::Fy2016
  class Q2 < Base

    def run!
      if start_report(Reports::DataQuality::Fy2016::Q2.first)
        @answers = setup_questions()
        @support = @answers.deep_dup
        @all_clients = fetch_all_clients()
        update_report_progress(percent: 75)
        @clients_with_issues = Set.new
        

        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    def fetch_all_clients
      headers = [
        :client_id, 
        :age, 
        :project_type, 
        :VeteranStatus, 
        :enrollment_group_id, 
        :project_id, 
        :data_source_id, 
        :first_date_in_program,
        :last_date_in_program,
      ]
      columns = replace_project_type_with_overlay(headers)
      
      all_client_scope.
        order(date: :asc).
        pluck(*columns).
        map do |row|
          Hash[headers.zip(row)]
        end.group_by do |row|
          row[:client_id]
        end
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
          value: 'Veteran Status (3.7)',
        },
        q3_a3: {
          title:  nil,
          value: 'Project Entry Date (3.10)',
        },
        q3_a4: {
          title:  nil,
          value: 'Relationship to Head of Household (3.15)',
        },
        q3_a5: {
          title:  nil,
          value: 'Client Location (3.16)',
        },
        q3_a6: {
          title:  nil,
          value: 'Disabling Condition (3.8)',
        },
        q3_b2: {
          title:  'Veteran Status (3.7) - Error Count',
          value: 0,
        },
        q3_c2: {
          title:  'Veteran Status (3.7) - % of Error Rate',
          value: 0,
        },
        q3_b3: {
          title:  'Project Entry Date (3.10) - Error Count',
          value: 0,
        },
        q3_c3: {
          title:  'Project Entry Date (3.10) - % of Error Rate',
          value: 0,
        },
        q3_b4: {
          title:  'Relationship to Head of Household (3.15) - Error Rate',
          value: 0,
        },
        q3_c4: {
          title:  'Relationship to Head of Household (3.15) - % of Error Rate',
          value: 0,
        },
        q3_b5: {
          title:  'Client Location (3.16) - Error Rate',
          value: 0,
        },
        q3_c5: {
          title:  'Client Location (3.16) - % of Error Rate',
          value: 0,
        },
        q3_b6: {
          title:  'Disabling Condition (3.8) - Error Rate',
          value: 0,
        },
        q3_c6: {
          title:  'Disabling Condition (3.8) - % of Error Rate',
          value: 0,
        },
      }
    end

  end
end