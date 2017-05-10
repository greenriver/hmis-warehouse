module ReportGenerators::DataQuality::Fy2016
  class Q1 < Base
    ADULT = 18

    def run!
      if start_report(Reports::DataQuality::Fy2016::Q1.first)
        @answers = setup_questions()
        @support = @answers.deep_dup
        @all_clients = fetch_all_clients()
        if @all_clients.any?
          add_total_clients_served()
          setup_age_categories()
          update_report_progress(percent: 25)
          add_age_answers()
          add_leaver_answers()
          add_stayer_answers()
          update_report_progress(percent: 50)
          add_veteran_answer()
          add_chronic_answers()
          add_youth_answers()
          add_household_head_answers()
          add_lts_answers()
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
        VeteranStatus: :VeteranStatus, 
        enrollment_group_id: :enrollment_group_id,
        project_id: :project_id,
        project_name: :project_name,
        data_source_id: :data_source_id, 
        RelationshipToHoH: :RelationshipToHoH,
        DisablingCondition: :DisablingCondition,
        ResidencePrior: :ResidencePrior,
        PreviousStreetESSH: :PreviousStreetESSH,
        DateToStreetESSH: :DateToStreetESSH,
        first_date_in_program: :first_date_in_program,
        last_date_in_program: :last_date_in_program,
        TimesHomelessPastThreeYears: :TimesHomelessPastThreeYears,
        MonthsHomelessPastThreeYears: :MonthsHomelessPastThreeYears,
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

    def add_total_clients_served
      @answers[:q1_b1][:value] = @all_clients.size
      @support[:q1_b1][:support] = add_support(
        headers: ['Client ID', 'Enrollments'],
        data: @all_clients.map{|id, enrollments| [id, enrollments.size]},
      )
    end


    def add_age_answers
      @answers[:q1_b2][:value] = @adults.size
      @answers[:q1_b3][:value] = @children.size
      @answers[:q1_b4][:value] = @unknown.size

      headers = ['Client ID', 'Age']
      @support[:q1_b2][:support] = add_support(headers: headers, data: @adults)
      @support[:q1_b3][:support] = add_support(headers: headers, data: @children)
      @support[:q1_b4][:support] = add_support(headers: headers, data: @unknown)

    end

    def add_leaver_answers
      @answers[:q1_b5][:value] = leavers.size
      @answers[:q1_b6][:value] = adult_leavers.size
      @answers[:q1_b7][:value] = adult_leavers_and_heads_of_household_leavers.size

      headers = ['Client ID', 'Age', 'Project Name', 'Entry Date', 'Exit Date']
      @support[:q1_b5][:support] = add_support(
        headers: headers, 
        data: leavers.map do |_, enrollment|
          [
            enrollment[:client_id], 
            enrollment[:age], 
            enrollment[:project_name], 
            enrollment[:first_date_in_program], 
            enrollment[:last_date_in_program]
          ]
        end
      )
      @support[:q1_b6][:support] = add_support(
        headers: headers, 
        data: adult_leavers.map do |_, enrollment|
          [
            enrollment[:client_id], 
            enrollment[:age], 
            enrollment[:project_name], 
            enrollment[:first_date_in_program], 
            enrollment[:last_date_in_program]
          ]
        end
      )
      @support[:q1_b7][:support] = add_support(
        headers: headers, 
        data: adult_leavers_and_heads_of_household_leavers.map do |_, enrollment|
          [
            enrollment[:client_id], 
            enrollment[:age], 
            enrollment[:project_name], 
            enrollment[:first_date_in_program], 
            enrollment[:last_date_in_program]
          ]
        end
      )
      
    end

    def add_stayer_answers
      @answers[:q1_b8][:value] = stayers.size
      @answers[:q1_b9][:value] = adult_stayers.size

      headers = ['Client ID', 'Age', 'Project Name', 'Entry Date', 'Exit Date']
      @support[:q1_b8][:support] = add_support(
        headers: headers, 
        data: stayers.map do |_, enrollment|
          [
            enrollment[:client_id], 
            enrollment[:age], 
            enrollment[:project_name], 
            enrollment[:first_date_in_program], 
            enrollment[:last_date_in_program]
          ]
        end
      )
      @support[:q1_b9][:support] = add_support(
        headers: headers, 
        data: adult_stayers.map do |_, enrollment|
          [
            enrollment[:client_id], 
            enrollment[:age], 
            enrollment[:project_name], 
            enrollment[:first_date_in_program], 
            enrollment[:last_date_in_program]
          ]
        end
      )

    end

    def add_veteran_answer
      veterans = @all_clients.select do |_, enrollments|
        enrollments.last[:VeteranStatus].to_i == 1
      end
      @answers[:q1_b10][:value] = veterans.size
      headers = ['Client ID', 'Veteran Status', 'Age']
      @support[:q1_b10][:support] = add_support(
        headers: headers, 
        data: veterans.map do |_, enrollments|
          enrollment = enrollments.last
          [
            enrollment[:client_id],
            HUD.no_yes_reasons_for_missing_data(enrollment[:VeteranStatus]),
            enrollment[:age], 
          ]
        end
      )
    end

    def add_chronic_answers
      disabled_clients = Hash.new
      living_situation_qualifies = Hash.new
      episodes_and_months_qualifies = Hash.new

      @all_clients.each do |id, enrollments|
        enrollment = enrollments.last

        disabled_clients[id] = enrollment if client_disabled?(enrollment: enrollment)
        
        living_situation_qualifies[id] = enrollment if living_situation_is_homeless(enrollment: enrollment)

        episodes_and_months_qualifies[id] = enrollment if four_or_more_episodes_and_12_months_or_365_days?(enrollment: enrollment)
      end
      chronic_ids = disabled_clients.keys & living_situation_qualifies.keys & episodes_and_months_qualifies.keys
      chronic = disabled_clients.select{|k,_| chronic_ids.include?(k)}
      @answers[:q1_b11][:value] = chronic.size
      @support[:q1_b11][:support] = add_support(
        headers: ['Client ID', 'Age', 'Project Name', 'Entry', 'Exit'], 
        data: chronic.map do |id, enrollment|
          [
            enrollment[:client_id],
            enrollment[:age],
            enrollment[:project_name],
            enrollment[:first_date_in_program],
            enrollment[:last_date_in_program],
          ]
        end
      )
    end

    # Youth = >= 12 and <= 24
    # Youth only household contains no one 25 or older
    # Parenting youth: household is a subset that also contains one or more additional members of 
    # age < 18 and RelationshipToHoH = 2
    def add_youth_answers
      youth_households = households.select do |_, household|
        # Only select each household once, when we hit the head
        if head_of_household?(household.first[:RelationshipToHoH])
          household[:household].select do |member|
            member[:age] >= 12 && member[:age] <= 24 if member[:age].present?
          end.count == household[:household].count
        end
      end

      @answers[:q1_b12][:value] = youth_households.size
      @support[:q1_b12][:support] = add_support(
        headers: ['Client ID', 'Age', 'Household ID', 'Members', 'Size'], 
        data: youth_households.map do |id, household|
          member = household[:household].first
          [
            id,
            member[:age],
            member[:household_id],
            household[:household].first[:household_id],
            household[:household].
              map{|m| m[:client_id]}.join(', '), 
            household[:household].size
          ]
        end
      )
      parenting_youth = youth_households.select do |id, household|
        household[:household].select do |member|
          adult?(member[:age]) && child_in_household?(member[:RelationshipToHoH])
        end.any?
      end

      @answers[:q1_b13][:value] = parenting_youth.size
      @support[:q1_b13][:support] = add_support(
        headers: ['Client ID', 'Age', 'Household ID', 'Members', 'Size', 'Composition'], 
        data: parenting_youth.map do |id, household|
          member = household[:household].first
          [
            id,
            member[:age],
            member[:household_id],
            household[:household].first[:household_id],
            household[:household].size,
            household[:household].
              map{|m| m[:client_id]}.join(', '),
          ]
        end
      )
    end

    def add_household_head_answers
      @answers[:q1_b14][:value] = adult_heads.size
      @support[:q1_b14][:support] = add_support(
        headers: ['Client ID', 'Household ID', 'Members', 'Size'], 
        data: adult_heads.map do |id, household|
          [
            id,
            household[:household].first[:household_id],
            household[:household].
              map{|m| m[:client_id]}.join(', '), 
            household[:household].size
          ]
        end
      )

      @answers[:q1_b15][:value] = other_heads.size
      @support[:q1_b15][:support] = add_support(
        headers: ['Client ID', 'Household ID', 'Members', 'Size'], 
        data: other_heads.map do |id, household|
          [
            id,
            household[:household].first[:household_id],
            household[:household].
              map{|m| m[:client_id]}.join(', '), 
            household[:household].size
          ]
        end
      )

    end

    def add_lts_answers
      # Any stayer who is RelationshipToHoH == 1 or age > 18 and has a stay lenght of 365 days or more
      lts = adult_stayers_and_heads_of_household_stayers.
        map do |id, enrollment|
          enrollment[:stay_length] = stay_length(client_id: id, entry_date: enrollment[:first_date_in_program], exit_date: enrollment[:enrollment_group_id])
          [id,enrollment]
        end.to_h.select do |_,enrollment|
          enrollment[:stay_length] >= 365
        end
      @answers[:q1_b16][:value] = lts.size
      @support[:q1_b16][:support] = add_support(
        headers: ['Client ID', 'Relationship to Head of Household', 'Stay Length'],
        data: lts.map do |id, enrollment|
          [id, enrollment[:RelationshipToHoH], enrollment[:stay_length]]
        end
      )
    end

    def setup_questions
      {
        q1_a1: {
          title:  nil,
          value: 'Total number of persons served',
        },
        q1_a2: {
          title:  nil,
          value: 'Number of adults (age 18 or over)',
        },
        q1_a3: {
          title:  nil,
          value: 'Number of children (under age 18)',
        },
        q1_a4: {
          title:  nil,
          value: 'Number of persons with unknown age',
        },
        q1_a5: {
          title:  nil,
          value: 'Number of leavers',
        },
        q1_a6: {
          title:  nil,
          value: 'Number of adult leavers',
        },
        q1_a7: {
          title:  nil,
          value: 'Number of adult and head of household leavers',
        },
        q1_a8: {
          title:  nil,
          value: 'Number of stayers',
        },
        q1_a9: {
          title:  nil,
          value: 'Number of adult stayers',
        },
        q1_a10: {
          title:  nil,
          value: 'Number of veterans',
        },
        q1_a11: {
          title:  nil,
          value: 'Number of chronically homeless persons',
        },
        q1_a12: {
          title:  nil,
          value: 'Number of youth under age 25',
        },
        q1_a13: {
          title:  nil,
          value: 'Number of parenting youth under age 25 with children',
        },
        q1_a14: {
          title:  nil,
          value: 'Number of adult heads of household',
        },
        q1_a15: {
          title:  nil,
          value: 'Number of child and unknown-age heads of household',
        },
        q1_a16: {
          title:  nil,
          value: 'Heads of households and adult stayers in the project 365 days or more',
        },

        q1_b1: {
          title: 'Total number of persons served ',
          value: 0,
        },
        q1_b2: {
          title: 'Number of adults (age 18 or over) ',
          value: 0,
        },
        q1_b3: {
          title: 'Number of children (under age 18) ',
          value: 0,
        },
        q1_b4: {
          title: 'Number of persons with unknown age ',
          value: 0,
        },
        q1_b5: {
          title: 'Number of leavers ',
          value: 0,
        },
        q1_b6: {
          title: 'Number of adult leavers ',
          value: 0,
        },
        q1_b7: {
          title: 'Number of adult and head of household leavers ',
          value: 0,
        },
        q1_b8: {
          title: 'Number of stayers ',
          value: 0,
        },
        q1_b9: {
          title: 'Number of adult stayers ',
          value: 0,
        },
        q1_b10: {
          title: 'Number of veterans ',
          value: 0,
        },
        q1_b11: {
          title: 'Number of chronically homeless persons ',
          value: 0,
        },
        q1_b12: {
          title: 'Number of youth under age 25 ',
          value: 0,
        },
        q1_b13: {
          title: 'Number of parenting youth under age 25 with children ',
          value: 0,
        },
        q1_b14: {
          title: 'Number of adult heads of household ',
          value: 0,
        },
        q1_b15: {
          title: 'Number of child and unknown-age heads of household ',
          value: 0,
        },
        q1_b16: {
          title: 'Heads of households and adult stayers in the project 365 days or more ',
          value: 0,
        },
      }
    end

  end
end