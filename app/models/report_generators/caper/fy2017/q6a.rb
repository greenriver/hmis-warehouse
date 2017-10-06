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

    def add_name_answers
      counted = Set.new # Only count each client once
      poor_quality = @all_clients.select do |id, (*,enrollment)|
        [8,9].include?(enrollment[:NameDataQuality])
      end
      counted += poor_quality.keys
      @clients_with_issues += poor_quality.keys
      @answers[:q6a_b2][:value] = poor_quality.size
      @support[:q6a_b2][:support] = add_support(
        headers: ['Client ID', 'Name Data Quality'],
        data: poor_quality.map do |id, (*,enrollment)|
          [
            id,
            HUD.name_data_quality(enrollment[:NameDataQuality])
          ]
        end
      )
      missing = @all_clients.select do |id, (*,enrollment)|
        (enrollment[:FirstName].blank? || 
          enrollment[:LastName].blank? || 
          enrollment[:NameDataQuality] == 99
        ) && ! counted.include?(id)
      end
      counted += missing.keys
      @clients_with_issues += missing.keys
      @answers[:q6a_c2][:value] = missing.size
      @support[:q6a_c2][:support] = add_support(
        headers: ['Client ID', 'First Name', 'Last Name'],
        data: missing.map do |id, (*,enrollment)|
          enrollment.values_at :client_id, :FirstName, :LastName
        end
      )
      quality_issues = @all_clients.select do |id, (*,enrollment)|
        enrollment[:NameDataQuality] == 2 && !counted.include?(id)
      end
      @clients_with_issues += quality_issues.keys
      @answers[:q6a_d2][:value] = quality_issues.size
      @support[:q6a_d2][:support] = add_support(
        headers: ['Client ID', 'First Name', 'Last Name'],
        data: poor_quality.map do |id, (*, enrollment)|
          enrollment.values_at :client_id, :FirstName, :LastName
        end
      )
      @answers[:q6a_e2][:value] = ((counted.size.to_f / all_client_count) * 100).round(2)
    end

    def add_ssn_answers
      counted = Set.new # Only count each client once
      poor_quality = @all_clients.select do |id, (*,enrollment)|
        [8,9].include?(enrollment[:SSNDataQuality])
      end
      counted += poor_quality.keys
      @clients_with_issues += poor_quality.keys
      @answers[:q6a_b3][:value] = poor_quality.size
      @support[:q6a_b3][:support] = add_support(
        headers: ['Client ID', 'SSN Data Quality'],
        data: poor_quality.map do |id, (*,enrollment)|
          [
            id,
            HUD.ssn_data_quality(enrollment[:SSNDataQuality])
          ]
        end
      )
      missing = @all_clients.select do |id, (*,enrollment)|
        enrollment[:SSN].blank? || enrollment[:SSNDataQuality] == 99 && ! counted.include?(id)
      end
      counted += missing.keys
      @clients_with_issues += missing.keys
      @answers[:q6a_c3][:value] = missing.size
      @support[:q6a_c3][:support] = add_support(
        headers: ['Client ID', 'First Name', 'Last Name'],
        data: missing.map do |id, (*,enrollment)|
          enrollment.values_at :client_id, :FirstName, :LastName
        end
      )
      quality_issues = @all_clients.select do |id, (*,enrollment)|
        collection_issues = enrollment[:SSNDataQuality] == 2
        valid = ::HUD.valid_social?(enrollment[:SSN])
        (! valid || collection_issues) && ! counted.include?(id)
      end
      @clients_with_issues += quality_issues.keys
      @answers[:q6a_d3][:value] = quality_issues.size
      @support[:q6a_d3][:support] = add_support(
        headers: ['Client ID', 'First Name', 'Last Name', 'SSN'],
        data: quality_issues.map do |id, (*,enrollment)|
          enrollment.values_at :client_id, :FirstName, :LastName, :SSN
        end
      )
      @answers[:q6a_e3][:value] = ((counted.size.to_f / all_client_count) * 100).round(2)
    end

    def add_dob_answers
      counted = Set.new # Only count each client once
      poor_quality = @all_clients.select do |id, (*,enrollment)|
        [8,9].include?(enrollment[:DOBDataQuality])
      end
      counted += poor_quality.keys
      @clients_with_issues += poor_quality.keys
      @answers[:q6a_b4][:value] = poor_quality.size
      @support[:q6a_b4][:support] = add_support(
        headers: ['Client ID', 'DOB Data Quality'],
        data: poor_quality.map do |id, (*,enrollment)|
          [
            id,
            HUD.dob_data_quality(enrollment[:DOBDataQuality])
          ]
          enrollment.values_at :client_id, :DOBDataQuality
        end
      )
      missing = @all_clients.select do |id, (*,enrollment)|
        enrollment[:DOB].blank? || enrollment[:DOBDataQuality] == 99 && ! counted.include?(id)
      end
      counted += missing.keys
      @clients_with_issues += missing.keys
      @answers[:q6a_c4][:value] = missing.size
      @support[:q6a_c4][:support] = add_support(
        headers: ['Client ID', 'First Name', 'Last Name'],
        data: missing.map do |id, (*,enrollment)|
          enrollment.values_at :client_id, :FirstName, :LastName
        end
      )
      too_early = '1915-01-01'.to_date
      quality_issues = @all_clients.select do |id, (*,enrollment)|
        if ( dob = enrollment[:DOB] ).present?
          # too old || too new || too late
          dob < too_early || dob > enrollment[:DateCreated] || dob >= enrollment[:first_date_in_program] # NOTE this differs from the method in q2; is it wrong?
        end
      end
      @clients_with_issues += quality_issues.keys
      @answers[:q6a_d4][:value] = quality_issues.size
      @support[:q6a_d4][:support] = add_support(
        headers: ['Client ID', 'First Name', 'Last Name', 'DOB'],
        data: quality_issues.map do |id, (*,enrollment)|
          enrollment.values_at :client_id, :FirstName, :LastName, :DOB
        end
      )
      @answers[:q6a_e4][:value] = ((counted.size.to_f / all_client_count) * 100).round(2)
    end

    def add_race_answers
      counted = Set.new # Only count each client once
      poor_quality = @all_clients.select do |id, (*,enrollment)|
        [8,9].include?(enrollment[:RaceNone])
      end
      counted += poor_quality.keys
      @clients_with_issues += poor_quality.keys
      @answers[:q6a_b5][:value] = poor_quality.size
      @support[:q6a_b5][:support] = add_support(
        headers: ['Client ID', 'RaceNone'],
        data: poor_quality.map do |id, (*,enrollment)|
          [
            id, 
            HUD.race_none(enrollment[:RaceNone]),
          ]
        end
      )
      missing = @all_clients.select do |id, (*,enrollment)|
        enrollment[:RaceNone] == 99 && ! counted.include?(id)
      end
      counted += missing.keys
      @clients_with_issues += missing.keys
      @answers[:q6a_c5][:value] = missing.size
      @support[:q6a_c5][:support] = add_support(
        headers: ['Client ID', 'RaceNone'],
        data: missing.map do |id, (*,enrollment)|
          [
            id, 
            HUD.race_none(enrollment[:RaceNone]),
          ]
        end
      )
      @answers[:q6a_e5][:value] = ((counted.size.to_f / all_client_count) * 100).round(2)
    end

    def add_ethnicity_answers
      counted = Set.new # Only count each client once
      poor_quality = @all_clients.select do |id, (*,enrollment)|
        [8,9].include?(enrollment[:Ethnicity])
      end
      counted += poor_quality.keys
      @clients_with_issues += poor_quality.keys
      @answers[:q6a_b6][:value] = poor_quality.size
      @support[:q6a_b6][:support] = add_support(
        headers: ['Client ID', 'Ethnicity'],
        data: poor_quality.map do |id, (*,enrollment)|
          [
            id, 
            HUD.ethnicity(enrollment[:Ethnicity]),
          ]
        end
      )
      missing = @all_clients.select do |id, (*,enrollment)|
        (enrollment[:Ethnicity].blank? || enrollment[:Ethnicity] == 99) && ! counted.include?(id)
      end
      counted += missing.keys
      @clients_with_issues += missing.keys
      @answers[:q6a_c6][:value] = missing.size
      @support[:q6a_c6][:support] = add_support(
        headers: ['Client ID', 'Ethnicity'],
        data: missing.map do |id, (*,enrollment)|
          [
            id, 
            HUD.ethnicity(enrollment[:Ethnicity]),
          ]
        end
      )
      @answers[:q6a_e6][:value] = ((counted.size.to_f / all_client_count) * 100).round(2)
    end

    def add_gender_answers
      counted = Set.new # Only count each client once
      poor_quality = @all_clients.select do |id, (*,enrollment)|
        [8,9].include?(enrollment[:Gender])
      end
      counted += poor_quality.keys
      @clients_with_issues += poor_quality.keys
      @answers[:q6a_b7][:value] = poor_quality.size
      @support[:q6a_b7][:support] = add_support(
        headers: ['Client ID', 'Gender'],
        data: poor_quality.map do |id, (*,enrollment)|
          [
            id,
            HUD.gender(enrollment[:Gender])
          ]
        end
      )
      missing = @all_clients.select do |id, (*,enrollment)|
        (enrollment[:Gender].blank? || enrollment[:Gender] == 99) && ! counted.include?(id)
      end
      counted += missing.keys
      @clients_with_issues += missing.keys
      @answers[:q6a_c7][:value] = missing.size
      @support[:q6a_c7][:support] = add_support(
        headers: ['Client ID', 'Gender'],
        data: missing.map do |id, (*,enrollment)|
          [
            id, 
            HUD.gender(enrollment[:Gender])
          ]
        end
      )
      @answers[:q6a_e7][:value] = ((counted.size.to_f / all_client_count * 100)).round(2)
    end

    def add_summary_info
      @answers[:q6a_e8][:value] = ((@clients_with_issues.size.to_f / all_client_count) * 100).round(2)
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