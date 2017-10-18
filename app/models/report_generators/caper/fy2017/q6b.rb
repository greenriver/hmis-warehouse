module ReportGenerators::CAPER::Fy2017
  # Data Quality: Universal Data Elements
  # equivalent to data quality q3
  class Q6b < Base

    def run!
      if start_report(Reports::CAPER::Fy2017::Q6b.first)
        @answers = setup_questions
        @support = @answers.deep_dup
        @all_clients = fetch_all_clients
        update_report_progress percent: 50
        if @all_clients.any?
          setup_age_categories
          update_report_progress percent: 5
          @clients_with_issues = Set.new
          data_methods = %i[
            veteran_answers
            entry_date_answers
            head_of_household_answers
            location_answers
            disabling_condition_answers
          ]
          data_methods.each_with_index do |method, i|
            send("add_#{method}")
            if i < data_methods.length - 1
              update_report_progress percent: 55 + ( 45 * i.to_f / data_methods.length ).round
            end
          end
        end
        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    # likely to be overridden
    def fetch_all_clients
      columns = columnize(
        age:                   sh_t,
        client_id:             sh_t,
        enrollment_group_id:   sh_t,
        project_id:            sh_t,
        data_source_id:        sh_t,
        first_date_in_program: sh_t,
        last_date_in_program:  sh_t,
        project_name:          sh_t,
        household_id:          sh_t,
        VeteranStatus:   c_t,
        RelationshipToHoH:  e_t,
        DisablingCondition: e_t,
        CoCCode: e_coc_t,
      ).merge({
        project_type: act_as_project_overlay
      })

      all_client_scope.
        joins( :project, { enrollment: :enrollment_coc_at_entry } ). # FIXME -- compare to equivalent in q3; this might be wrong
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

    def add_veteran_answers
      vets = @all_clients.select do |id, (*,enrollment)|
        age = enrollment[:age]
        veteran_status = enrollment[:VeteranStatus]
        [8,9,99,nil].include?(veteran_status) ||
        (veteran_status == 1 && age.present? && age < ADULT)
      end
      @clients_with_issues += vets.keys
      @answers[:q3_b2][:value] = vets.size
      @support[:q3_b2][:support] = add_support(
        headers: ['Client ID', 'Vetetan Status', 'Age'],
        data: vets.map do |id, (*,enrollment)|
          [
            id, 
            HUD.no_yes_reasons_for_missing_data(enrollment[:VeteranStatus]),
            enrollment[:age]
          ]
        end
      )
      @answers[:q3_c2][:value] = ((vets.size.to_f / @adults.size) * 100).round(2) #/ to fix syntax highlighting
    end

    # like q3 enrollments_overlap? but stripped down so I could follow the logic
    def enrollments_overlap?(en_1, en_2)
      s1, e1 = en_1.values_at :first_date_in_program, :last_date_in_program
      s2, e2 = en_2.values_at :first_date_in_program, :last_date_in_program
      e1 ||= Date.today
      e2 ||= Date.today
      s1 < e2 && s2 < e1
    end

    def add_entry_date_answers
      entry_date_answers = @all_clients.select do |id, enrollments|
        # Find any overlapping enrollments within the same project
        plural = enrollments.group_by do |enrollment|
          enrollment[:project_id]
        end.select{ |_,v| v.size > 1 }.values.flatten(1)
        plural.combination(2).any? do |en_1, en_2|
          enrollments_overlap? en_1, en_2
        end
      end
      @clients_with_issues += entry_date_answers.keys
      @answers[:q3_b3][:value] = entry_date_answers.size
      @support[:q3_b3][:support] = add_support(
        headers: ['Client ID', 'Most Recent Project', 'Entry Date', 'Exit Date'],
        data: entry_date_answers.map do |id, (*,enrollment)|
          enrollment.values_at :client_id, :project_name, :first_date_in_program, :last_date_in_program # took away to_sym on project_name
        end
      )
      @answers[:q3_c3][:value] = ((entry_date_answers.size.to_f / all_client_count) * 100).round(2)
    end

    # see q3 method of same name
    def household_members(enrollment)
      @all_households ||= begin
        counter = 0
        all = {}
        households.values.each do |m|
          enrollment = m[:household].first
          all[
            enrollment.values_at :data_source_id, :project_id, :household_id, :first_date_in_program
          ] = m[:household]
          counter += 1
          log_with_memory("#{counter} households processed")
        end
        all
      end
      @all_households[ enrollment.values_at :data_source_id, :project_id, :household_id, :first_date_in_program ]
    end

    def add_head_of_household_answers
      counter = 0
      poor_quality = @all_clients.select do |id, (*,enrollment)|
        flag = false
        if !valid_household_relationship?(enrollment)
          # we have a missing, or non-usable relationship
          flag = true
        else
          household = household_members(enrollment)
          relationships = household.map do |enrollment|
            enrollment[:RelationshipToHoH]
          end
          hoh_count = relationships.count(1)
          if hoh_count == 0
            # No one is marked as the head of household
            flag = true
          elsif hoh_count > 1
            # Too many heads of household
            flag = true
          end
        end
        counter += 1
        if counter % 500 == 0
          GC.start
          if debug
            log_with_memory("processed #{counter}")
          end
        end
        flag
      end
      @clients_with_issues += poor_quality.keys
      @answers[:q3_b4][:value] = poor_quality.size
      @support[:q3_b4][:support] = add_support(
        headers: ['Client ID', 'Relationship to HoH', 'Project', 'Entry Date', 'Exit Date'],
        data: poor_quality.map do |id, (*,enrollment)|
          enrollment.values_at :client_id, :RelationshipToHoH, :project_name, :last_date_in_program # took away to_sym on project_name
        end
      )
      @answers[:q3_c4][:value] = ((poor_quality.size.to_f / all_client_count) * 100).round(2)
    end

    def add_location_answers
      poor_quality = @all_clients.select do |id, (*,enrollment)|
        head_of_household?(enrollment) && !valid_coc_code?(enrollment)   # I think the q3 logic unrolls to this
      end
      @clients_with_issues += poor_quality.keys
      @answers[:q3_b5][:value] = poor_quality.size
      @support[:q3_b5][:support] = add_support(
        headers: ['Client ID', 'CoC Code', 'Project'],
        data: poor_quality.map do |id, (*,enrollment)|
          enrollment.values_at :client_id, :CoCCode, :project_name
        end
      )
      # Only count against heads of household
      @answers[:q3_c5][:value] = ((poor_quality.size.to_f / (adult_heads.count + other_heads.count)) * 100).round(2)
    end

    def add_disabling_condition_answers
      poor_quality = @all_clients.select do |id, (*,enrollment)|
        [8,9,99,nil].include?(enrollment[:DisablingCondition]) || enrollment[:DisablingCondition] == 0 && client_disabled?(enrollment)
      end
      @clients_with_issues += poor_quality.keys
      @answers[:q3_b6][:value] = poor_quality.size
      @support[:q3_b6][:support] = add_support(
        headers: ['Client ID', 'Disabling Condition'],
        data: poor_quality.map do |id, (*,enrollment)|
          [
            id, 
            HUD.disability_type(enrollment[:DisablingCondition]),
          ]
        end
      )
      @answers[:q3_c6][:value] = ((poor_quality.size.to_f / all_client_count) * 100).round(2) 
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