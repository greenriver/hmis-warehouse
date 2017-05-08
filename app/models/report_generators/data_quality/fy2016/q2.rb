module ReportGenerators::DataQuality::Fy2016
  class Q2 < Base

    def run!
      if start_report(Reports::DataQuality::Fy2016::Q2.first)
        @answers = setup_questions()
        @support = @answers.deep_dup
        @all_clients = fetch_all_clients()
        if @all_clients.any?
          update_report_progress(percent: 75)
          @clients_with_issues = Set.new
          add_name_answers()
          add_ssn_answers()
          add_dob_answers()
          add_race_answers()
          add_ethnicity_answers()
          add_gender_answers()
          add_summary_info()
        end

        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    def add_name_answers
      counted = Set.new # Only count each client once
      poor_quality = @all_clients.select do |id, enrollments|
        enrollment = enrollments.last
        [8,9].include?(enrollment[:NameDataQuality].to_i)
      end
      counted += poor_quality.keys
      @clients_with_issues += poor_quality.keys
      @answers[:q2_b2][:value] = poor_quality.size
      @support[:q2_b2][:support] = add_support(
        headers: ['Client ID', 'Name Data Quality'],
        data: poor_quality.map do |id, enrollments|
          [id, enrollments.last[:NameDataQuality]]
        end
      )
      missing = @all_clients.select do |id, enrollments|
        enrollment = enrollments.last
        (enrollment[:FirstName].blank? || 
          enrollment[:LastName].blank? || 
          enrollment[:NameDataQuality].to_i == 99
        ) && ! counted.include?(id)
      end
      counted += missing.keys
      @clients_with_issues += missing.keys
      @answers[:q2_c2][:value] = missing.size
      @support[:q2_c2][:support] = add_support(
        headers: ['Client ID', 'First Name', 'Last Name'],
        data: missing.map do |id, enrollments|
          enrollment = enrollments.last
          [id, enrollment[:FirstName], enrollment[:LastName]]
        end
      )
      quality_issues = @all_clients.select do |id, enrollments|
        enrollment = enrollments.last
        enrollment[:NameDataQuality].to_i == 2 && ! counted.include?(id)
      end
      @clients_with_issues += quality_issues.keys
      @answers[:q2_d2][:value] = quality_issues.size
      @support[:q2_d2][:support] = add_support(
        headers: ['Client ID', 'First Name', 'Last Name'],
        data: poor_quality.map do |id, enrollments|
          enrollment = enrollments.last
          [id, enrollment[:FirstName], enrollment[:LastName]]
        end
      )
      @answers[:q2_e2][:value] = ((counted.size.to_f / all_client_count) * 100).round(2)
    end

    def add_ssn_answers
      counted = Set.new # Only count each client once
      poor_quality = @all_clients.select do |id, enrollments|
        enrollment = enrollments.last
        [8,9].include?(enrollment[:SSNDataQuality].to_i)
      end
      counted += poor_quality.keys
      @clients_with_issues += poor_quality.keys
      @answers[:q2_b3][:value] = poor_quality.size
      @support[:q2_b3][:support] = add_support(
        headers: ['Client ID', 'SSN Data Quality'],
        data: poor_quality.map do |id, enrollments|
          [id, enrollments.last[:SSNDataQuality]]
        end
      )
      missing = @all_clients.select do |id, enrollments|
        enrollment = enrollments.last
        enrollment[:SSN].blank? || enrollment[:SSNDataQuality].to_i == 99 && ! counted.include?(id)
      end
      counted += missing.keys
      @clients_with_issues += missing.keys
      @answers[:q2_c3][:value] = missing.size
      @support[:q2_c3][:support] = add_support(
        headers: ['Client ID', 'First Name', 'Last Name'],
        data: missing.map do |id, enrollments|
          enrollment = enrollments.last
          [id, enrollment[:FirstName], enrollment[:LastName]]
        end
      )
      quality_issues = @all_clients.select do |id, enrollments|
        enrollment = enrollments.last
        collection_issues = enrollment[:SSNDataQuality].to_i == 2
        valid = ::HUD.valid_social?(enrollment[:SSN])
        (! valid || collection_issues) && ! counted.include?(id)
      end
      @clients_with_issues += quality_issues.keys
      @answers[:q2_d3][:value] = quality_issues.size
      @support[:q2_d3][:support] = add_support(
        headers: ['Client ID', 'First Name', 'Last Name', 'SSN'],
        data: quality_issues.map do |id, enrollments|
          enrollment = enrollments.last
          [id, enrollment[:FirstName], enrollment[:LastName], enrollment[:SSN]]
        end
      )
      @answers[:q2_e3][:value] = ((counted.size.to_f / all_client_count) * 100).round(2)
    end

    def add_dob_answers
      counted = Set.new # Only count each client once
      poor_quality = @all_clients.select do |id, enrollments|
        enrollment = enrollments.last
        [8,9].include?(enrollment[:DOBDataQuality].to_i)
      end
      counted += poor_quality.keys
      @clients_with_issues += poor_quality.keys
      @answers[:q2_b4][:value] = poor_quality.size
      @support[:q2_b4][:support] = add_support(
        headers: ['Client ID', 'DOB Data Quality'],
        data: poor_quality.map do |id, enrollments|
          [id, enrollments.last[:DOBDataQuality]]
        end
      )
      missing = @all_clients.select do |id, enrollments|
        enrollment = enrollments.last
        enrollment[:DOB].blank? || enrollment[:DOBDataQuality].to_i == 99 && ! counted.include?(id)
      end
      counted += missing.keys
      @clients_with_issues += missing.keys
      @answers[:q2_c4][:value] = missing.size
      @support[:q2_c4][:support] = add_support(
        headers: ['Client ID', 'First Name', 'Last Name'],
        data: missing.map do |id, enrollments|
          enrollment = enrollments.last
          [id, enrollment[:FirstName], enrollment[:LastName]]
        end
      )
      quality_issues = @all_clients.select do |id, enrollments|
        enrollment = enrollments.last
        too_old = enrollment[:DOB].present? && enrollment[:DOB] < '1915-01-01'.to_date
        too_new = enrollment[:DOB].present? && enrollment[:DOB] > enrollment[:DateCreated]
        too_late = enrollment[:DOB].present? && enrollment[:DOB] >= enrollment[:first_date_in_program]
      end
      @clients_with_issues += quality_issues.keys
      @answers[:q2_d4][:value] = quality_issues.size
      @support[:q2_d4][:support] = add_support(
        headers: ['Client ID', 'First Name', 'Last Name', 'DOB'],
        data: quality_issues.map do |id, enrollments|
          enrollment = enrollments.last
          [id, enrollment[:FirstName], enrollment[:LastName], enrollment[:DOB]]
        end
      )
      @answers[:q2_e4][:value] = ((counted.size.to_f / all_client_count) * 100).round(2)
    end

    def add_race_answers
      counted = Set.new # Only count each client once
      poor_quality = @all_clients.select do |id, enrollments|
        enrollment = enrollments.last
        [8,9].include?(enrollment[:RaceNone].to_i)
      end
      counted += poor_quality.keys
      @clients_with_issues += poor_quality.keys
      @answers[:q2_b5][:value] = poor_quality.size
      @support[:q2_b5][:support] = add_support(
        headers: ['Client ID', 'RaceNone'],
        data: poor_quality.map do |id, enrollments|
          enrollment = enrollments.last
          [
            id, 
            HUD.race_none(enrollments.last[:RaceNone]),
          ]
        end
      )
      missing = @all_clients.select do |id, enrollments|
        enrollment = enrollments.last
        enrollment[:RaceNone].to_i == 99 && ! counted.include?(id)
      end
      counted += missing.keys
      @clients_with_issues += missing.keys
      @answers[:q2_c5][:value] = missing.size
      @support[:q2_c5][:support] = add_support(
        headers: ['Client ID', 'RaceNone'],
        data: missing.map do |id, enrollments|
          enrollment = enrollments.last
          [
            id, 
            HUD.race_none(enrollment[:RaceNone]),
          ]
        end
      )
      @answers[:q2_e5][:value] = ((counted.size.to_f / all_client_count) * 100).round(2)
    end

    def add_ethnicity_answers
      counted = Set.new # Only count each client once
      poor_quality = @all_clients.select do |id, enrollments|
        enrollment = enrollments.last
        [8,9].include?(enrollment[:Ethnicity].to_i)
      end
      counted += poor_quality.keys
      @clients_with_issues += poor_quality.keys
      @answers[:q2_b6][:value] = poor_quality.size
      @support[:q2_b6][:support] = add_support(
        headers: ['Client ID', 'Ethnicity'],
        data: poor_quality.map do |id, enrollments|
          enrollment = enrollments.last
          [
            id, 
            HUD.ethnicity(enrollment[:Ethnicity]),
          ]
        end
      )
      missing = @all_clients.select do |id, enrollments|
        enrollment = enrollments.last
        (enrollment[:Ethnicity].blank? || enrollment[:Ethnicity].to_i == 99) && ! counted.include?(id)
      end
      counted += missing.keys
      @clients_with_issues += missing.keys
      @answers[:q2_c6][:value] = missing.size
      @support[:q2_c6][:support] = add_support(
        headers: ['Client ID', 'Ethnicity'],
        data: missing.map do |id, enrollments|
          enrollment = enrollments.last
          [
            id, 
            HUD.ethnicity(enrollment[:Ethnicity]),
          ]
        end
      )
      @answers[:q2_e6][:value] = ((counted.size.to_f / all_client_count) * 100).round(2)
      
    end

    def add_gender_answers
      counted = Set.new # Only count each client once
      poor_quality = @all_clients.select do |id, enrollments|
        enrollment = enrollments.last
        [8,9].include?(enrollment[:Gender].to_i)
      end
      counted += poor_quality.keys
      @clients_with_issues += poor_quality.keys
      @answers[:q2_b7][:value] = poor_quality.size
      @support[:q2_b7][:support] = add_support(
        headers: ['Client ID', 'Gender'],
        data: poor_quality.map do |id, enrollments|
          enrollment = enrollments.last
          [
            id,
            HUD.gender(enrollment[:Gender])
          ]
        end
      )
      missing = @all_clients.select do |id, enrollments|
        enrollment = enrollments.last
        (enrollment[:Gender].blank? || enrollment[:Gender].to_i == 99) && ! counted.include?(id)
      end
      counted += missing.keys
      @clients_with_issues += missing.keys
      @answers[:q2_c7][:value] = missing.size
      @support[:q2_c7][:support] = add_support(
        headers: ['Client ID', 'Gender'],
        data: missing.map do |id, enrollments|
          enrollment = enrollments.last
          [
            id, 
            HUD.gender(enrollment[:Gender])
          ]
        end
      )
      @answers[:q2_e7][:value] = ((counted.size.to_f / all_client_count * 100)).round(2)
      
    end

    def add_summary_info
      @answers[:q2_e8][:value] = ((@clients_with_issues.size.to_f / all_client_count) * 100).round(2)
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
        NameDataQuality: :NameDataQuality,
        FirstName: :FirstName, 
        LastName: :LastName, 
        SSN: :SSN, 
        SSNDataQuality: :SSNDataQuality,
        DOB: :DOB,
        DOBDataQuality: :DOBDataQuality,
        DateCreated: "#{GrdaWarehouse::Hud::Enrollment.quoted_table_name}.DateCreated",
        first_date_in_program: :first_date_in_program,
        last_date_in_program: :last_date_in_program,
        Ethnicity: :Ethnicity,
        Gender: :Gender,
        RaceNone: :RaceNone,
      }
                  
      all_client_scope.
        joins(:project, :enrollment).
        order(date: :asc).
        pluck(*columns.values).
        map do |row|
          Hash[columns.keys.zip(row)]
        end.group_by do |row|
          row[:client_id]
        end
    end

    def setup_questions
      {
        q2_a1: {
          title:  nil,
          value: 'Data Element',
        },
        q2_b1: {
          title:  nil,
          value: 'Client Doesn’t Know/Refused',
        },
        q2_c1: {
          title:  nil,
          value: 'Information Missing',
        },
        q2_d1: {
          title:  nil,
          value: 'Data Issues',
        },
        q2_e1: {
          title:  nil,
          value: '% of Error Rate',
        },
        q2_a2: {
          title:  nil,
          value: 'Name (3.1)',
        },
        q2_a3: {
          title:  nil,
          value: 'Social Security Number (3.2)',
        },
        q2_a4: {
          title:  nil,
          value: 'Date of Birth (3.3)',
        },
        q2_a5: {
          title:  nil,
          value: 'Race (3.4)',
        },
        q2_a6: {
          title:  nil,
          value: 'Ethnicity (3.5)',
        },
        q2_a7: {
          title:  nil,
          value: 'Gender (3.6)',
        },
        q2_a8: {
          title:  nil,
          value: 'Overall Score',
        },
        q2_b2: {
          title:  'Name - Client Doesn\'t Know/Refused',
          value: 0,
        },
        q2_c2: {
          title:  'Name - Information Missing',
          value: 0,
        },
        q2_d2: {
          title:  'Name - Data Issues',
          value: 0,
        },
        q2_e2: {
          title:  'Name - % of Error Rate',
          value: 0,
        },
        q2_b3: {
          title:  'SSN - Client Doesn\'t Know/Refused',
          value: 0,
        },
        q2_c3: {
          title:  'SSN - Information Missing',
          value: 0,
        },
        q2_d3: {
          title:  'SSN - Data Issues',
          value: 0,
        },
        q2_e3: {
          title:  'SSN - % of Error Rate',
          value: 0,
        },
        q2_b4: {
          title:  'DOB - Client Doesn\'t Know/Refused',
          value: 0,
        },
        q2_c4: {
          title:  'DOB - Information Missing',
          value: 0,
        },
        q2_d4: {
          title:  'DOB - Data Issues',
          value: 0,
        },
        q2_e4: {
          title:  'DOB - % of Error Rate',
          value: 0,
        },
        q2_b5: {
          title:  'Race - Client Doesn\'t Know/Refused',
          value: 0,
        },
        q2_c5: {
          title:  'Race - Information Missing',
          value: 0,
        },
        q2_e5: {
          title:  'Race - % of Error Rate',
          value: 0,
        },
        q2_b6: {
          title:  'Ethnicity - Client Doesn\'t Know/Refused',
          value: 0,
        },
        q2_c6: {
          title:  'Ethnicity - Information Missing',
          value: 0,
        },
        q2_e6: {
          title:  'Ethnicity - % of Error Rate',
          value: 0,
        },
        q2_b7: {
          title:  'Gender - Client Doesn\'t Know/Refused',
          value: 0,
        },
        q2_c7: {
          title:  'Gender - Information Missing',
          value: 0,
        },
        q2_e7: {
          title:  'Gender - % of Error Rate',
          value: 0,
        },
        q2_e8: {
          title:  'Overall Score - % of Error Rate',
          value: 0,
        },
      }
    end

  end
end