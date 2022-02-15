###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ReportGenerators::DataQuality::Fy2017
  class Q3 < Base
    ADULT = 18

    def run!
      if start_report(Reports::DataQuality::Fy2017::Q3.first)
        @answers = setup_questions()
        @support = @answers.deep_dup
        @all_client_ids = fetch_all_client_ids()
        @client_personal_ids = personal_ids(@all_client_ids)
        if @all_client_ids.any?
          setup_age_categories(@all_client_ids)
          update_report_progress(percent: 5)
          log_with_memory("5 percent")
          @clients_with_issues = Set.new
          add_veteran_answers()
          update_report_progress(percent: 15)
          log_with_memory("15 percent")
          add_entry_date_answers()
          update_report_progress(percent: 20)
          log_with_memory("20 percent")
          add_head_of_household_answers()
          update_report_progress(percent: 60)
          log_with_memory("60 percent")
          add_location_answers()
          update_report_progress(percent: 75)
          log_with_memory("75 percent")
          add_disabling_condition_answers()
        end
        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    def columns
      @columns ||= {
        client_id: she_t[:client_id],
        project_type: she_t[:computed_project_type],
        VeteranStatus: c_t[:VeteranStatus],
        enrollment_group_id: she_t[:enrollment_group_id],
        project_id: she_t[:project_id],
        data_source_id: she_t[:data_source_id],
        first_date_in_program: she_t[:first_date_in_program],
        last_date_in_program: she_t[:last_date_in_program],
        project_name: she_t[:project_name],
        RelationshipToHoH: e_t[:RelationshipToHoH],
        household_id: she_t[:household_id],
        CoCCode: ec_t[:CoCCode],
        DisablingCondition: e_t[:DisablingCondition],
      }
    end

    def fetch_all_client_ids
      client_batch_scope.
        pluck(:client_id)
    end

    def client_batch_scope
      active_client_scope.
        distinct.
        includes(enrollment: :enrollment_coc_at_entry).
        joins(:project)
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

    def add_veteran_answers
      counted = Set.new # Only count each client once
      poor_quality = {}
      @all_client_ids.each_slice(250) do |client_ids|
        client_batch(client_ids).each do |client_id, enrollments|
          enrollment = enrollments.last
          age = enrollment[:age]
          veteran_status = enrollment[:VeteranStatus]
          include_client = [8,9,nil].include?(veteran_status) || (veteran_status == 1 && age.present? && age < ADULT)

          poor_quality[client_id] = enrollments.last if include_client
        end
      end
      counted += poor_quality.keys
      @clients_with_issues += poor_quality.keys
      @answers[:q3_b2][:value] = poor_quality.size
      @support[:q3_b2][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'Vetetan Status', 'Age'],
        data: poor_quality.map do |id, enrollment|
          [
            id,
            @client_personal_ids[id].join(', '),
            HUD.no_yes_reasons_for_missing_data(enrollment[:VeteranStatus]),
            enrollment[:age]
          ]
        end
      )
      @answers[:q3_c2][:value] = ((counted.size.to_f / @adults.size) * 100).round(2)
    end

    def add_entry_date_answers
      counted = Set.new # Only count each client once
      poor_quality = {}
      @all_client_ids.each_slice(250) do |client_ids|
        client_batch(client_ids).each do |client_id, enrollments|
          # Find any overlapping enrollments within the same project
          overlap = false
          more_than_one_at_project = enrollments.group_by do |enrollment|
            [enrollment[:project_id], enrollment[:data_source_id]]
          end.select {|_,v| v.size > 1}

          more_than_one_at_project.
            values.
            flatten(1).
            combination(2) do |en_1, en_2|
              overlap = enrollments_overlap?(en_1, en_2)
              break if overlap
            end
          poor_quality[client_id] = enrollments.last if overlap
        end
      end
      counted += poor_quality.keys
      @clients_with_issues += poor_quality.keys
      @answers[:q3_b3][:value] = poor_quality.size
      @support[:q3_b3][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'Most Recent Project', 'Entry Date', 'Exit Date'],
        data: poor_quality.map do |id, enrollment|
          [
            id,
            @client_personal_ids[id].join(', '),
            enrollment[:project_name].to_sym,
            enrollment[:first_date_in_program],
            enrollment[:last_date_in_program],
          ]
        end
      )
      @answers[:q3_c3][:value] = ((counted.size.to_f / all_client_count) * 100).round(2)
    end

    def add_head_of_household_answers
      log_with_memory("Starting Household Answers")
      log_with_memory("All Client's size: #{@all_client_ids.size}")
      counted = Set.new # Only count each client once
      poor_quality = {}
      @all_client_ids.each_slice(250) do |client_ids|
        client_batch(client_ids).each do |client_id, enrollments|
          flag = false
          enrollment = enrollments.last
          if ! valid_household_relationship?(enrollment[:RelationshipToHoH])
            log_with_memory("non-usable relationship")
            # we have a missing, or non-usable relationship
            flag = true
          else
            log_with_memory("gathering household members")
            household = household_members(enrollment)
            # if we had two enrollments on the same day, this may not find us
            next unless household.present?

            relationships = household.map do |enrollment|
              enrollment[:RelationshipToHoH]
            end
            hoh_count = relationships.count(1)
            if hoh_count == 0
              # No one is marked as the head of household
              log_with_memory("no HOH")
              flag = true
            elsif hoh_count > 1
              # Too many heads of household
              log_with_memory("too many HOH")
              flag = true
            end
          end
          poor_quality[client_id] = enrollment if flag
        end
      end
      log_with_memory("Found all poor quality (#{poor_quality.size})")
      counted += poor_quality.keys
      @clients_with_issues += poor_quality.keys
      @answers[:q3_b4][:value] = poor_quality.size
      @support[:q3_b4][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'Relationship to HoH', 'Project', 'Entry Date', 'Exit Date'],
        data: poor_quality.map do |id, enrollment|
          [
            id,
            @client_personal_ids[id].join(', '),
            enrollment[:RelationshipToHoH],
            enrollment[:project_name].to_sym,
            enrollment[:first_date_in_program],
            enrollment[:last_date_in_program],
          ]
        end
      )
      @answers[:q3_c4][:value] = ((counted.size.to_f / all_client_count) * 100).round(2)
    end

    def add_location_answers
      counted = Set.new # Only count each client once
      poor_quality = {}
      @all_client_ids.each_slice(250) do |client_ids|
        client_batch(client_ids).each do |client_id, enrollments|
          flag = false
          enrollment = enrollments.last
          if ! head_of_household?(enrollment[:RelationshipToHoH])
            flag = false
          else
            # if the CoCCode doesn't match the approved pattern (including missing), flag it
            flag = enrollment[:CoCCode].blank? || ! valid_coc_code?(enrollment[:CoCCode])
          end
          poor_quality[client_id] = enrollment if flag
        end
      end
      counted += poor_quality.keys
      @clients_with_issues += poor_quality.keys
      @answers[:q3_b5][:value] = poor_quality.size
      @support[:q3_b5][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'CoC Code', 'Project'],
        data: poor_quality.map do |id, enrollment|
          [
            id,
            @client_personal_ids[id].join(', '),
            enrollment[:CoCCode],
            enrollment[:project_name]
          ]
        end
      )
      # Only count against heads of household
      @answers[:q3_c5][:value] = ((counted.size.to_f / (adult_heads.count + other_heads.count)) * 100).round(2)
    end

    def add_disabling_condition_answers
      counted = Set.new # Only count each client once
      poor_quality = {}
      @all_client_ids.each_slice(250) do |client_ids|
        client_batch(client_ids).each do |client_id, enrollments|
          enrollment = enrollments.last
          flag = false
          if [8,9,nil].include?(enrollment[:DisablingCondition])
            flag = true
          elsif enrollment[:DisablingCondition] == 0
            flag = client_disabled?(enrollment: enrollment)
          end
          poor_quality[client_id] = enrollment if flag
        end
      end
      counted += poor_quality.keys
      @clients_with_issues += poor_quality.keys
      @answers[:q3_b6][:value] = poor_quality.size
      @support[:q3_b6][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'Disabling Condition'],
        data: poor_quality.map do |id, enrollment|
          [
            id,
            @client_personal_ids[id].join(', '),
            HUD.disability_type(enrollment[:DisablingCondition]),
          ]
        end
      )
      @answers[:q3_c6][:value] = ((counted.size.to_f / all_client_count) * 100).round(2)
    end

    def enrollments_overlap?(en_1, en_2)
      en_1_start = en_1[:first_date_in_program]
      en_1_end = en_1[:last_date_in_program] || Date.current
      en_2_start = en_2[:first_date_in_program]
      en_2_end = en_2[:last_date_in_program] || Date.current
      # Excellent discussion of why this works:
      # http://stackoverflow.com/questions/325933/determine-whether-two-date-ranges-overlap
      # en_1_start < en_2_end && en_1_end > en_2_start
      dates_overlap(en_1_start, en_1_end, en_2_start, en_2_end)
    end

    def household_members(enrollment)
      all_households[
        [
          enrollment[:data_source_id],
          enrollment[:project_id],
          enrollment[:household_id],
          enrollment[:first_date_in_program],
        ]
      ]
      # The previous uses too much RAM for large data sets
      # This may be slower, but shouldn't require additional RAM
      # households.values.select do |row|
      #   row[:key] == [
      #     enrollment[:data_source_id],
      #     enrollment[:project_id],
      #     enrollment[:household_id],
      #     enrollment[:first_date_in_program]
      #   ]
      #   end.first[:household]
    end

    def all_households
      @all_households ||= begin
        counter = 0
        all = {}
        households.values.each do |m|
          en = m[:household].first
          all[
            [
              en[:data_source_id],
              en[:project_id],
              en[:household_id],
              en[:first_date_in_program],
            ]
          ] = m[:household]
          counter += 1
          log_with_memory("#{counter} households processed")
        end
        all
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
