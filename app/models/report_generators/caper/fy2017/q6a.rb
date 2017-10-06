module ReportGenerators::CAPER::Fy2017
  # Data Quality: Personally Identifiable Information
  # this is more or less equivalent to the fy2016 data quality question q2
  class Q6a < Base

    def run!
      if start_report(Reports::CAPER::Fy2017::Q6a.first)
        @answers = setup_questions
        @support = @answers.deep_dup
        @all_clients = fetch_all_clients
        update_report_progress percent: 50
        if @all_clients.any?
          @clients_with_issues = Set.new
          if @all_clients.any?
            data_methods = %i[
              name_answers
              ssn_answers
              dob_answers
              race_answers
              ethnicity_answers
              gender_answers
              summary_info
            ]
            data_methods.each_with_index do |method, i|
              send("add_#{method}")
              if i < data_methods.length - 1
                update_report_progress percent: 50 + ( 50 * i.to_f / data_methods.length ).round
              end
            end
          end
        end
        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    def fetch_all_clients
      columns = columnize(
        client_id:             sh_t,
        # age:                   sh_t,  # made redundant by age calculation below
        enrollment_group_id:   sh_t,
        project_id:            sh_t,
        data_source_id:        sh_t,
        first_date_in_program: sh_t,
        last_date_in_program:  sh_t,
        VeteranStatus:   c_t,
        NameDataQuality: c_t,
        FirstName:       c_t,
        LastName:        c_t,
        SSN:             c_t,
        SSNDataQuality:  c_t,
        DOB:             c_t,
        DOBDataQuality:  c_t,
        Ethnicity:       c_t,
        Gender:          c_t,
        RaceNone:        c_t,
        DateCreated: e_t,
      ).merge({
        project_type: act_as_project_overlay,
      })
      all_client_scope.
        joins( :project, :enrollment ).
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

    def add_name_answers
    end

    def add_ssn_answers
    end

    def add_dob_answers
    end

    def add_race_answers
    end

    def add_ethnicity_answers
    end

    def add_gender_answers
    end

    def add_summary_info
    end

    def setup_questions
      {
        q6a_a1: {
          title:  nil,
          value: 'Data Element',
        },
        q6a_b1: {
          title:  nil,
          value: 'Client Doesn’t Know/Refused',
        },
        q6a_c1: {
          title:  nil,
          value: 'Information Missing',
        },
        q6a_d1: {
          title:  nil,
          value: 'Data Issues',
        },
        q6a_e1: {
          title:  nil,
          value: '% of Error Rate',
        },
        q6a_a2: {
          title:  nil,
          value: 'Name (3.1)',
        },
        q6a_a3: {
          title:  nil,
          value: 'Social Security Number (3.2)',
        },
        q6a_a4: {
          title:  nil,
          value: 'Date of Birth (3.3)',
        },
        q6a_a5: {
          title:  nil,
          value: 'Race (3.4)',
        },
        q6a_a6: {
          title:  nil,
          value: 'Ethnicity (3.5)',
        },
        q6a_a7: {
          title:  nil,
          value: 'Gender (3.6)',
        },
        q6a_a8: {
          title:  nil,
          value: 'Overall Score',
        },
        q6a_b2: {
          title:  'Name - Client Doesn\'t Know/Refused',
          value: 0,
        },
        q6a_c2: {
          title:  'Name - Information Missing',
          value: 0,
        },
        q6a_d2: {
          title:  'Name - Data Issues',
          value: 0,
        },
        q6a_e2: {
          title:  'Name - % of Error Rate',
          value: 0,
        },
        q6a_b3: {
          title:  'SSN - Client Doesn\'t Know/Refused',
          value: 0,
        },
        q6a_c3: {
          title:  'SSN - Information Missing',
          value: 0,
        },
        q6a_d3: {
          title:  'SSN - Data Issues',
          value: 0,
        },
        q6a_e3: {
          title:  'SSN - % of Error Rate',
          value: 0,
        },
        q6a_b4: {
          title:  'DOB - Client Doesn\'t Know/Refused',
          value: 0,
        },
        q6a_c4: {
          title:  'DOB - Information Missing',
          value: 0,
        },
        q6a_d4: {
          title:  'DOB - Data Issues',
          value: 0,
        },
        q6a_e4: {
          title:  'DOB - % of Error Rate',
          value: 0,
        },
        q6a_b5: {
          title:  'Race - Client Doesn\'t Know/Refused',
          value: 0,
        },
        q6a_c5: {
          title:  'Race - Information Missing',
          value: 0,
        },
        q6a_e5: {
          title:  'Race - % of Error Rate',
          value: 0,
        },
        q6a_b6: {
          title:  'Ethnicity - Client Doesn\'t Know/Refused',
          value: 0,
        },
        q6a_c6: {
          title:  'Ethnicity - Information Missing',
          value: 0,
        },
        q6a_e6: {
          title:  'Ethnicity - % of Error Rate',
          value: 0,
        },
        q6a_b7: {
          title:  'Gender - Client Doesn\'t Know/Refused',
          value: 0,
        },
        q6a_c7: {
          title:  'Gender - Information Missing',
          value: 0,
        },
        q6a_e7: {
          title:  'Gender - % of Error Rate',
          value: 0,
        },
        q6a_e8: {
          title:  'Overall Score - % of Error Rate',
          value: 0,
        },
      }
    end

  end
end