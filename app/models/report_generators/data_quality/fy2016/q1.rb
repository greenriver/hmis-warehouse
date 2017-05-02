module ReportGenerators::DataQuality::Fy2016
  class Q1 < Base
    ADULT = 18

    def run!
      if start_report(Reports::DataQuality::Fy2016::Q1.first)
        @answers = setup_questions()
        @support = @answers.deep_dup
        @all_clients = fetch_all_clients()
        add_total_clients_served()
        setup_age_categories()
        update_report_progress(percent: 25)
        add_age_answers()
        @leavers = calculate_leavers()
        update_report_progress(percent: 50)
        @stayers = calculate_stayers()
        add_leaver_answers()
        add_stayer_answers()
        add_veteran_answer()

        add_youth_answers()
        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    def fetch_all_clients
      headers = [:client_id, :age, :project_type, :VeteranStatus, :enrollment_group_id, :project_id, :data_source_id]
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

    def setup_age_categories
      clients_with_ages = @all_clients.map do |id, enrollments|
        [id, enrollments.last[:age]]
      end
      @adults = clients_with_ages.select do |_, age|
        age >= ADULT if age.present?
      end
      @children = clients_with_ages.select do |_, age|
        age < ADULT if age.present?
      end
      @unknown = clients_with_ages.select do |_, age|
        age.blank?
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
      @answers[:q1_b5][:value] = @leavers.size

      adult_leavers = @leavers.select do |_, enrollment|
        enrollment[:age] >= ADULT if enrollment[:age].present?
      end
      @answers[:q1_b6][:value] = adult_leavers.size
      adult_heads_of_households = adult_leavers.select do |_, enrollment|
        enrollment[:RelationshipToHoH].to_i == 1
      end
      @answers[:q1_b7][:value] = adult_heads_of_households.size

      headers = ['Client ID', 'Age', 'Project Name', 'Entry Date', 'Exit Date']
      @support[:q1_b5][:support] = add_support(
        headers: headers, 
        data: @leavers.map do |_, enrollment|
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
        data: adult_heads_of_households.map do |_, enrollment|
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
      @answers[:q1_b8][:value] = @stayers.size
      staying_adults = @stayers.select do |_, enrollment|
        enrollment[:age] >= ADULT if enrollment[:age].present?
      end
      @answers[:q1_b9][:value] = staying_adults.size

      headers = ['Client ID', 'Age', 'Project Name', 'Entry Date', 'Exit Date']
      @support[:q1_b8][:support] = add_support(
        headers: headers, 
        data: @stayers.map do |_, enrollment|
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
        data: staying_adults.map do |_, enrollment|
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
      headers = ['Client ID', 'Age']
      @support[:q1_b10][:support] = add_support(
        headers: headers, 
        data: veterans.map do |_, enrollments|
          enrollment = enrollments.last
          [
            enrollment[:client_id], 
            enrollment[:age], 
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
        household.select do |member|
          member[:age] >= 12 && member[:age] <= 24 if member[:age].present?
        end.any?
      end

      @answers[:q1_b12][:value] = youth_households.size
      @support[:q1_b12][:support] = add_support(
        headers: ['Client ID', 'Members', 'Size'], 
        data: youth_households.map do |id, household|
          [id, household.map{|m| m[:client_id]}.join(', '), household.size]
        end
      )
      parenting_youth = youth_households.select do |_, household|
        household.select do |member|
          member[:age].present? && member[:age] < ADULT && member[:RelationshipToHoH] ==2
        end
      end

      @answers[:q1_b13][:value] = parenting_youth.size
      @support[:q1_b13][:support] = add_support(
        headers: ['Client ID', 'Members', 'Size'], 
        data: youth_households.map do |id, household|
          [id, household.map{|m| m[:client_id]}.join(', '), household.size]
        end
      )

    end

    def add_household_head_answers
      adult_heads = households.select do |id, household|
        household.select do |member|
          member[:age].present? && member[:age] >= ADULT && member[:RelationshipToHoH] == 1
        end.any?
      end
      other_heads = households.select do |id, household|
        household.select do |member|
          (member[:age].present? && member[:age] < ADULT || member[:age].blank?) && member[:RelationshipToHoH] == 1
        end.any?
      end
      @answers[:q1_b14][:value] = adult_heads.size
      @support[:q1_b14][:support] = add_support(
        headers: ['Client ID', 'Members', 'Size'], 
        data: adult_heads.map do |id, household|
          [id, household.map{|m| m[:client_id]}.join(', '), household.size]
        end
      )

      @answers[:q1_b15][:value] = other_heads.size
      @support[:q1_b14][:support] = add_support(
        headers: ['Client ID', 'Members', 'Size'], 
        data: other_heads.map do |id, household|
          [id, household.map{|m| m[:client_id]}.join(', '), household.size]
        end
      )

    end

    def add_lts_answers
      # Any stayer who is RelationshipToHoH == 1 or age > 18 and has a stay lenght of 365 days or more
      lts = @stayers.select do |id, enrollment|
          enrollment[:RelationshipToHoH] == 1 || enrollment[:age].present? && enrollment[:age] >= ADULT
        end.
        map do |id, enrollment|
          enrollment[:stay_length] = GrdaWarehouse::ServiceHistory.service.
            where(
              client_id: id, 
              first_date_in_program: enrollment[:first_date_in_program],
              enrollment_group_id: enrollment[:enrollment_group_id]
            ).
            select(:date).
            distinct.
            count
        end.select do |enrollment|
          enrollment[:stay_length] >= 365
        end
      @answers[:q1_b16][:value] = lts.size
      @support[:q1_b16][:support] = add_support(
        headers: ['Client ID', 'Relationship to Head of Household', 'Stay Length'],
        data: lts.map do |enrollment|
          [enrollment[:client_id], enrollment[:RelationshipToHoH], enrollment[:stay_length]]
        end
      )
    end

    def households
      @households ||= {}.tap do |h|

        columns = [:client_id, :age, :head_of_household_id, :household_id, :RelationshipToHoH]
        @all_clients.each do |id, enrollments|
          enrollment = enrollments.last
          h[id] = GrdaWarehouse::ServiceHistory.entry.
            where(household_id: enrollment[:household_id],
              first_date_in_program: enrollment[:first_date_in_program], project_id: enrollment[:project_id]).
            joins(:client, :enrollment).
            pluck(*columns).map do |row|
              Hash[columns.zip(row)]
            end
        end
      end

    end

    def calculate_leavers
      # 1. A "system leaver" is any client who has exited from one or more of the relevant projects between [report start date] and [report end date] and who
      # is not active in any of the relevant projects as of the [report end date].
      # 2. The client must be an adult to be included.
      columns = [:client_id, :first_date_in_program, :last_date_in_program, :project_id, :age, :DOB, :enrollment_group_id, :data_source_id, :project_tracking_method, :project_name, :RelationshipToHoH, :household_id]

      client_id_scope = GrdaWarehouse::ServiceHistory.entry.
        ongoing(on_date: @report.options['report_end'])

      client_id_scope = add_filters(scope: client_id_scope)

      leavers_scope = GrdaWarehouse::ServiceHistory.entry.
        ended_between(start_date: @report.options['report_start'], 
          end_date: @report.options['report_end'].to_date + 1.days).
        where.not(
          client_id: client_id_scope.
            select(:client_id).
            distinct
        ).
        joins(:client, :enrollment)
        
      leavers_scope = add_filters(scope: leavers_scope)

      leavers = leavers_scope.
        order(client_id: :asc, first_date_in_program: :asc).
        pluck(*columns).map do |row|
          Hash[columns.zip(row)]
        end.group_by do |row|
          row[:client_id]
        end.map do |id,enrollments| 
          # We only care about the last enrollment
          [id, enrollments.last]
        end.to_h
    end

    def calculate_stayers
      # 1. A "system stayer" is a client active in any one or more of the relevant projects as of the [report end date]. CoC Performance Measures Programming Specifications
      # Page 24 of 41
      # 2. The client must have at least 365 days in latest stay to be included in this measure, using either bed-night or entry exit (you have to count the days) 
      # 3. The client must be an adult to be included in this measure.
      columns = [:client_id, :first_date_in_program, :last_date_in_program, :project_id, :age, :DOB, :enrollment_group_id, :data_source_id, :project_tracking_method, :project_name, :RelationshipToHoH, :household_id]

      stayers_scope = GrdaWarehouse::ServiceHistory.entry.
        ongoing(on_date: @report.options['report_end']).
        joins(:client, :enrollment)

      stayers_scope = add_filters(scope: stayers_scope)

      stayers = stayers_scope.
        order(client_id: :asc, first_date_in_program: :asc).
        pluck(*columns).map do |row|
          Hash[columns.zip(row)]
        end.group_by do |row|
          row[:client_id]
        end.map do |id,enrollments| 
          # We only care about the last enrollment
          [id, enrollments.last]
        end.to_h
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