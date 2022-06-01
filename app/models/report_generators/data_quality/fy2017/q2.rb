###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ReportGenerators::DataQuality::Fy2017
  class Q2 < Base

    def run!
      if start_report(Reports::DataQuality::Fy2017::Q2.first)
        @answers = setup_questions()
        @support = @answers.deep_dup
        @all_client_ids = fetch_all_client_ids()
        @client_personal_ids = personal_ids(@all_client_ids)
        if @all_client_ids.any?
          update_report_progress(percent: 15)
          @clients_with_issues = Set.new
          add_name_answers()
          update_report_progress(percent: 25)
          add_ssn_answers()
          update_report_progress(percent: 45)
          add_dob_answers()
          update_report_progress(percent: 55)
          add_race_answers()
          update_report_progress(percent: 65)
          add_ethnicity_answers()
          update_report_progress(percent: 75)
          add_gender_answers()
          update_report_progress(percent: 85)
          add_summary_info()
        end

        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    def add_name_answers
      counted = Set.new # Only count each client once
      poor_quality = {}
      missing = {}
      quality_issues = {}
      @all_client_ids.each_slice(500) do |client_ids|
        client_batch(client_ids).each do |client_id, enrollments|
          enrollment = enrollments.last
          poor_quality_client = [8,9].include?(enrollment[:NameDataQuality].to_i)
          missing_client = (
            enrollment[:FirstName].blank? ||
            enrollment[:LastName].blank? ||
            enrollment[:NameDataQuality].to_i == 99
          )
          data_quality_client = enrollment[:NameDataQuality].to_i == 2

          if poor_quality_client
            poor_quality[client_id] = enrollment
          elsif missing_client
            missing[client_id] = enrollment
          elsif data_quality_client
            quality_issues[client_id] = enrollment
          end
        end
      end
      counted += poor_quality.keys
      counted += missing.keys
      counted += quality_issues.keys

      @clients_with_issues += poor_quality.keys
      @clients_with_issues += missing.keys
      @clients_with_issues += quality_issues.keys

      @answers[:q2_b2][:value] = poor_quality.size
      @support[:q2_b2][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'Name Data Quality'],
        data: poor_quality.map do |id, enrollment|
          [
            id,
            @client_personal_ids[id].join(', '),
            enrollment[:NameDataQuality],
          ]
        end
      )

      @answers[:q2_c2][:value] = missing.size
      @support[:q2_c2][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'First Name', 'Last Name'],
        data: missing.map do |id, enrollment|
          [
            id,
            @client_personal_ids[id].join(', '),
            enrollment[:FirstName],
            enrollment[:LastName],
          ]
        end
      )

      @answers[:q2_d2][:value] = quality_issues.size
      @support[:q2_d2][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'First Name', 'Last Name'],
        data: poor_quality.map do |id, enrollment|
          [
            id,
            @client_personal_ids[id].join(', '),
            enrollment[:FirstName],
            enrollment[:LastName],
          ]
        end
      )
      @answers[:q2_e2][:value] = counted.size
      @answers[:q2_f2][:value] = ((counted.size.to_f / all_client_count) * 100).round(2)
    end

    def add_ssn_answers
      counted = Set.new # Only count each client once
      poor_quality = {}
      missing = {}
      quality_issues = {}
      @all_client_ids.each_slice(500) do |client_ids|
        client_batch(client_ids).each do |client_id, enrollments|
          enrollment = enrollments.last
          poor_quality_client = [8,9].include?(enrollment[:SSNDataQuality].to_i)
          missing_client = enrollment[:SSN].blank? || enrollment[:SSNDataQuality].to_i == 99
          collection_issues = enrollment[:SSNDataQuality].to_i == 2
          valid = ::HUD.valid_social?(enrollment[:SSN])
          data_quality_client = (! valid || collection_issues)

          if poor_quality_client
            poor_quality[client_id] = enrollment
          elsif missing_client
            missing[client_id] = enrollment
          elsif data_quality_client
            quality_issues[client_id] = enrollment
          end
        end
      end
      counted += poor_quality.keys
      counted += missing.keys
      counted += quality_issues.keys

      @clients_with_issues += poor_quality.keys
      @clients_with_issues += missing.keys
      @clients_with_issues += quality_issues.keys

      @answers[:q2_b3][:value] = poor_quality.size
      @support[:q2_b3][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'SSN Data Quality'],
        data: poor_quality.map do |id, enrollment|
          [
            id,
            @client_personal_ids[id].join(', '),
            enrollment[:SSNDataQuality],
          ]
        end
      )

      @answers[:q2_c3][:value] = missing.size
      @support[:q2_c3][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'First Name', 'Last Name'],
        data: missing.map do |id, enrollment|
          [
            id,
            @client_personal_ids[id].join(', '),
            enrollment[:FirstName],
            enrollment[:LastName],
          ]
        end
      )

      @answers[:q2_d3][:value] = quality_issues.size
      @support[:q2_d3][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'First Name', 'Last Name', 'SSN'],
        data: quality_issues.map do |id, enrollment|
          [
            id,
            @client_personal_ids[id].join(', '),
            enrollment[:FirstName],
            enrollment[:LastName],
            enrollment[:SSN],
          ]
        end
      )
      @answers[:q2_e3][:value] = counted.size
      @answers[:q2_f3][:value] = ((counted.size.to_f / all_client_count) * 100).round(2)
    end

    def add_dob_answers
      counted = Set.new # Only count each client once
      poor_quality = {}
      missing = {}
      quality_issues = {}
      @all_client_ids.each_slice(500) do |client_ids|
        client_batch(client_ids).each do |client_id, enrollments|
          enrollment = enrollments.last
          poor_quality_client = [8,9].include?(enrollment[:DOBDataQuality].to_i)
          missing_client = enrollment[:DOB].blank? || enrollment[:DOBDataQuality].to_i == 99
          approximate = enrollment[:DOBDataQuality].to_i == 2
          too_old = enrollment[:DOB].present? && enrollment[:DOB] < '1915-01-01'.to_date
          too_new = enrollment[:DOB].present? && enrollment[:DOB] > enrollment[:DateCreated]
          too_late = enrollment[:DOB].present? && enrollment[:head_of_household] && enrollment[:DOB] >= enrollment[:first_date_in_program]
          data_quality_client = approximate || too_old || too_new || too_late

          if poor_quality_client
            poor_quality[client_id] = enrollment
          elsif missing_client
            missing[client_id] = enrollment
          elsif data_quality_client
            quality_issues[client_id] = enrollment
          end
        end
      end
      counted += poor_quality.keys
      counted += missing.keys
      counted += quality_issues.keys

      @clients_with_issues += poor_quality.keys
      @clients_with_issues += missing.keys
      @clients_with_issues += quality_issues.keys

      @answers[:q2_b4][:value] = poor_quality.size
      @support[:q2_b4][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'DOB Data Quality'],
        data: poor_quality.map do |id, enrollment|
          [
            id,
            @client_personal_ids[id].join(', '),
            enrollment[:DOBDataQuality],
          ]
        end
      )

      @answers[:q2_c4][:value] = missing.size
      @support[:q2_c4][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'First Name', 'Last Name'],
        data: missing.map do |id, enrollment|
          [
            id,
            @client_personal_ids[id].join(', '),
            enrollment[:FirstName],
            enrollment[:LastName],
          ]
        end
      )

      @answers[:q2_d4][:value] = quality_issues.size
      @support[:q2_d4][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'First Name', 'Last Name', 'DOB'],
        data: quality_issues.map do |id, enrollment|
          [
            id,
            @client_personal_ids[id].join(', '),
            enrollment[:FirstName],
            enrollment[:LastName],
            enrollment[:DOB],
          ]
        end
      )
      @answers[:q2_e4][:value] = counted.size
      @answers[:q2_f4][:value] = ((counted.size.to_f / all_client_count) * 100).round(2)
    end

    def add_race_answers
      counted = Set.new # Only count each client once
      poor_quality = {}
      missing = {}
      quality_issues = {}
      @all_client_ids.each_slice(500) do |client_ids|
        client_batch(client_ids).each do |client_id, enrollments|
          enrollment = enrollments.last
          poor_quality_client = [8,9].include?(enrollment[:RaceNone].to_i)
          missing_client = enrollment[:RaceNone].to_i == 99

          if poor_quality_client
            poor_quality[client_id] = enrollment
          elsif missing_client
            missing[client_id] = enrollment
          end
        end
      end
      counted += poor_quality.keys
      counted += missing.keys

      @clients_with_issues += poor_quality.keys
      @clients_with_issues += missing.keys

      @answers[:q2_b5][:value] = poor_quality.size
      @support[:q2_b5][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'RaceNone'],
        data: poor_quality.map do |id, enrollment|
          [
            id,
            @client_personal_ids[id].join(', '),
            HUD.race_none(enrollment[:RaceNone]),
          ]
        end
      )

      @answers[:q2_c5][:value] = missing.size
      @support[:q2_c5][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'RaceNone'],
        data: missing.map do |id, enrollment|
          [
            id,
            @client_personal_ids[id].join(', '),
            HUD.race_none(enrollment[:RaceNone]),
          ]
        end
      )
      @answers[:q2_e5][:value] = counted.size
      @answers[:q2_f5][:value] = ((counted.size.to_f / all_client_count) * 100).round(2)
    end

    def add_ethnicity_answers
      counted = Set.new # Only count each client once
      poor_quality = {}
      missing = {}
      quality_issues = {}
      @all_client_ids.each_slice(500) do |client_ids|
        client_batch(client_ids).each do |client_id, enrollments|
          enrollment = enrollments.last
          poor_quality_client = [8,9].include?(enrollment[:Ethnicity].to_i)
          missing_client = (enrollment[:Ethnicity].blank? || enrollment[:Ethnicity].to_i == 99)

          if poor_quality_client
            poor_quality[client_id] = enrollment
          elsif missing_client
            missing[client_id] = enrollment
          end
        end
      end
      counted += poor_quality.keys
      counted += missing.keys

      @clients_with_issues += poor_quality.keys
      @clients_with_issues += missing.keys

      @answers[:q2_b6][:value] = poor_quality.size
      @support[:q2_b6][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'Ethnicity'],
        data: poor_quality.map do |id, enrollment|
          [
            id,
            @client_personal_ids[id].join(', '),
            HUD.ethnicity(enrollment[:Ethnicity]),
          ]
        end
      )

      @answers[:q2_c6][:value] = missing.size
      @support[:q2_c6][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'Ethnicity'],
        data: missing.map do |id, enrollment|
          [
            id,
            @client_personal_ids[id].join(', '),
            HUD.ethnicity(enrollment[:Ethnicity]),
          ]
        end
      )
      @answers[:q2_e6][:value] = counted.size
      @answers[:q2_f6][:value] = ((counted.size.to_f / all_client_count) * 100).round(2)
    end

    def add_gender_answers
      counted = Set.new # Only count each client once
      poor_quality = {}
      missing = {}
      quality_issues = {}
      @all_client_ids.each_slice(500) do |client_ids|
        client_batch(client_ids).each do |client_id, enrollments|
          enrollment = enrollments.last
          poor_quality_client = [8,9].include?(enrollment[:Gender].to_i)
          missing_client = (enrollment[:Gender].blank? || enrollment[:Gender].to_i == 99)

          if poor_quality_client
            poor_quality[client_id] = enrollment
          elsif missing_client
            missing[client_id] = enrollment
          end
        end
      end
      counted += poor_quality.keys
      counted += missing.keys

      @clients_with_issues += poor_quality.keys
      @clients_with_issues += missing.keys

      @answers[:q2_b7][:value] = poor_quality.size
      @support[:q2_b7][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'Gender'],
        data: poor_quality.map do |id, enrollment|
          [
            id,
            @client_personal_ids[id].join(', '),
            HUD.gender(enrollment[:Gender])
          ]
        end
      )

      @answers[:q2_c7][:value] = missing.size
      @support[:q2_c7][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'Gender'],
        data: missing.map do |id, enrollment|
          [
            id,
            @client_personal_ids[id].join(', '),
            HUD.gender(enrollment[:Gender])
          ]
        end
      )
      @answers[:q2_e7][:value] = counted.size
      @answers[:q2_f7][:value] = ((counted.size.to_f / all_client_count * 100)).round(2)
    end

    def add_summary_info
      @answers[:q2_e8][:value] = @clients_with_issues.size
      @answers[:q2_f8][:value] = ((@clients_with_issues.size.to_f / all_client_count) * 100).round(2)
    end

    def columns
      @columns ||= {
        client_id: she_t[:client_id],
        age: she_t[:age],
        project_type: she_t[:computed_project_type],
        VeteranStatus: c_t[:VeteranStatus],
        enrollment_group_id: she_t[:enrollment_group_id],
        project_id: she_t[:project_id],
        data_source_id: she_t[:data_source_id],
        NameDataQuality: c_t[:NameDataQuality],
        FirstName: c_t[:FirstName],
        LastName: c_t[:LastName],
        SSN: c_t[:SSN],
        SSNDataQuality: c_t[:SSNDataQuality],
        DOB: c_t[:DOB],
        DOBDataQuality: c_t[:DOBDataQuality],
        DateCreated: e_t[:DateCreated],
        first_date_in_program: she_t[:first_date_in_program],
        last_date_in_program: she_t[:last_date_in_program],
        Ethnicity: c_t[:Ethnicity],
        Gender: c_t[:Gender],
        RaceNone: c_t[:RaceNone],
        head_of_household: she_t[:head_of_household],
      }
    end

    def fetch_all_client_ids
      client_batch_scope.
        distinct.
        pluck(:client_id)
    end

    def client_batch_scope
      active_client_scope.
        joins(:project, :enrollment)
    end

    def client_batch(client_ids)
      client_batch_scope.
        where(client_id: client_ids).
        order(first_date_in_program: :asc).
        pluck(*columns.values).
        map do |row|
          enrollment = Hash[columns.keys.zip(row)]
          enrollment[:age] = age_for_report(dob: enrollment[:DOB], enrollment: enrollment)
          enrollment
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
          value: 'Client Doesn\'t Know/Refused',
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
          value: 'Total',
        },
        q2_f1: {
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
          title:  'Total',
          value: 0,
        },
        q2_f2: {
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
          title:  'Total',
          value: 0,
        },
        q2_f3: {
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
          title:  'Total',
          value: 0,
        },
        q2_f4: {
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
          title:  'Total',
          value: 0,
        },
        q2_f5: {
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
          title:  'Total',
          value: 0,
        },
        q2_f6: {
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
          title:  'Total',
          value: 0,
        },
        q2_f7: {
          title:  'Gender - % of Error Rate',
          value: 0,
        },
        q2_e8: {
          title:  'Total',
          value: 0,
        },
        q2_f8: {
          title:  'Overall Score - % of Error Rate',
          value: 0,
        },
      }
    end

  end
end
