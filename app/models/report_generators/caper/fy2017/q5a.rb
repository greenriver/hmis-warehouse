module ReportGenerators::CAPER::Fy2017
  # Report Validations Table
  class Q5a < Base

    def run!
      if start_report(Reports::CAPER::Fy2017::Q5a.first)
        @answers = setup_questions
        @support = @answers.deep_dup
        @all_clients = fetch_all_clients
        if @all_clients.any?
          data_methods = %i[
            total_number_served
            number_adults
            number_children
            number_unknown_age
            number_leavers
            number_adult_leavers
            number_adult_and_hoh_leavers
            number_stayers
            number_adult_stayers
            number_veterans
            number_chronically_homeless
            number_youth_under_25
            number_parenting_youth_under_25
            number_adult_hoh
            number_children_and_unknown_age_hoh
            hoh_and_adult_stayers_of_365_days_or_more
          ]
          data_methods.each_with_index do |method, i|
            send("add_#{method}")
            if i < data_methods.length - 1
              update_report_progress percent: ( 100 * i.to_f / data_methods.length ).round
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
        age:                   sh_t,
        client_id:             sh_t, 
        project_id:            sh_t,
        project_name:          sh_t,
        data_source_id:        sh_t,
        first_date_in_program: sh_t,
        last_date_in_program:  sh_t,
        household_id:          sh_t,
        FirstName:     c_t,
        LastName:      c_t,
        VeteranStatus: c_t,
        DOB:           c_t,
        RelationshipToHoH: e_t,
      )
      all_client_scope.
        joins( :project, :enrollment ).
        order(date: :asc).
        pluck(*columns.values).
        map do |row|
          Hash[columns.keys.zip(row)]
        end.map do |enrollment|
          enrollment[:age] = age_for_report(dob: enrollment[:DOB], enrollment: enrollment)
          enrollment
        end.group_by do |row|
          row[:client_id]
        end
    end

    def youth_households
      @youth_households ||= households.select do |_, household|
        # Only select each household once, when we hit the head
        if head_of_household?(household[:household].first)
          household[:household].select do |member|
            member[:age] >= 12 && member[:age] <= 24 if member[:age].present?
          end.count == household[:household].count
        end
      end
    end

    def client_data( key, sorted,
        headers: ['Client ID', 'First Name', 'LastName'],
        columns: %i( client_id FirstName LastName )
      )
      @answers[key][:value] = sorted.count
      @support[key][:support] = add_support(
        headers: headers,
        data: sorted.map do |_,data|
          datum = data.is_a?(Array) ? data.last : data  # by default, take last (most recent)
          datum.values_at *columns
        end
      )
    end

    def add_total_number_served
      filtered = @all_clients
      client_data :q5a_b1, filtered
    end

    def add_number_adults
      filtered = @all_clients.select{ |h| adult? h }
      client_data :q5a_b2, filtered
    end

    def add_number_children
      filtered = @all_clients.select{ |h| child? h }
      client_data :q5a_b3, filtered
    end

    def add_number_unknown_age
      filtered = @all_clients.select{ |h| unknown_age? h }
      client_data :q5a_b4, filtered
    end

    def add_number_leavers
      filtered = leavers
      client_data :q5a_b5, filtered
    end

    def add_number_adult_leavers
      filtered = leavers.select{ |h| adult? h }
      client_data :q5a_b6, filtered
    end

    def add_number_adult_and_hoh_leavers
      filtered = leavers.select{ |h| adult?(h) || head_of_household?(h)  }  # NOTE as in the data quality report, I am interpreting "and" to mean the union rather than the intersection
      client_data :q5a_b7, filtered
    end

    def add_number_stayers
      filtered = stayers
      client_data :q5a_b8, filtered
    end

    def add_number_adult_stayers
      filtered = stayers.select{ |h| adult? h }
      client_data :q5a_b9, filtered
    end

    def add_number_veterans
      filtered = @all_clients.select{ |h| veteran? h }
      client_data :q5a_b10, filtered
    end

    # Copied from data quality q1. See FIXMEs
    def add_number_chronically_homeless
      disabled_clients              = {}
      living_situation_qualifies    = {}
      episodes_and_months_qualifies = {}

      @all_clients.each do |id, enrollments|
        enrollment = enrollments.last

        disabled_clients[id] = enrollment if client_disabled? enrollment  # FIXME (see below) why is being disabled a requirement for being chronically homeless?
        
        living_situation_qualifies[id] = enrollment if living_situation_is_homeless? enrollment

        episodes_and_months_qualifies[id] = enrollment if four_or_more_episodes_and_12_months_or_365_days? enrollment
      end
      chronic_ids = disabled_clients.keys & living_situation_qualifies.keys & episodes_and_months_qualifies.keys
      chronic = disabled_clients.select{ |k,_| chronic_ids.include? k }  # FIXME this logic makes no sense to me. Why are only disabled clients potentially chronically homeless?
      client_data :q5a_b11, chronic.values,
        headers: ['Client ID', 'Age', 'Project Name', 'Entry', 'Exit'],
        columns: %i[ client_id age project_name first_date_in_program last_date_in_program ]
    end

    # copied from add_youth_answers in data quality q1: q1_b12
    def add_number_youth_under_25
      @answers[:q5a_b12][:value] = youth_households.count
      @support[:q5a_b12][:support] = add_support(
        headers: ['Client ID', 'Age', 'Household ID', 'Members', 'Size'],
        data: youth_households.map do |id, household|
          member = household[:household].first
          [
            id,
            member[:age],
            member[:household_id],
            household[:household].map{ |m| m[:client_id] }.join(', '),
            household[:household].size
          ]
        end
      )
    end

    # copied from add_youth_answers in data quality q1: q1_b13
    def add_number_parenting_youth_under_25
      parenting_youth = youth_households.select do |id, household|
        household[:household].select do |member|
          adult?(member) && child_in_household?(member)
        end.any?
      end
      @answers[:q5a_b13][:value] = parenting_youth.count
      @support[:q5a_b13][:support] = add_support(
        headers: ['Client ID', 'Age', 'Household ID', 'Members', 'Size'],
        data: youth_households.map do |id, household|
          member = household[:household].first
          [
            id,
            member[:age],
            member[:household_id],
            household[:household].map{ |m| m[:client_id] }.join(', '),
            household[:household].size
          ]
        end
      )
    end

    # q1_b14
    def add_number_adult_hoh
      adult_heads = households.select do |id, household|
        household[:household].select do |member|
          adult?(member) && head_of_household?(member)
        end.any?
      end
      @answers[:q5a_b14][:value] = adult_heads.size
      @support[:q5a_b14][:support] = add_support(
        headers: ['Client ID', 'Household ID', 'Members', 'Size'], 
        data: adult_heads.map do |id, household|
          [
            id,
            household[:household].first[:household_id],
            household[:household].map{ |m| m[:client_id] }.join(', '),
            household[:household].size
          ]
        end
      )
    end

    # copied from add_youth_answers in data quality q1: q1_b15
    def add_number_children_and_unknown_age_hoh
      other_heads = households.select do |id, household|
        household[:household].select do |member|
          ! adult?(member) && head_of_household?(member)
        end.any?
      end
      @answers[:q5a_b15][:value] = other_heads.size
      @support[:q5a_b15][:support] = add_support(
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

    # copied from add_youth_answers in data quality q1: q1_b16
    def add_hoh_and_adult_stayers_of_365_days_or_more
      lts = adult_stayers_and_heads_of_household_stayers.each do |id, enrollment|
        enrollment[:stay_length] = stay_length_for_adult_hoh(
          client_id: id,
          entry_date: enrollment[:first_date_in_program],
          enrollment_group_id: enrollment[:enrollment_group_id]
        )
      end.select do |_,enrollment|
        enrollment[:stay_length] >= 365
      end
      @answers[:q5a_b16][:value] = lts.size
      @support[:q5a_b16][:support] = add_support(
        headers: ['Client ID', 'Relationship to Head of Household', 'Stay Length'],
        data: lts.map do |id, enrollment|
          [ id, enrollment[:RelationshipToHoH], enrollment[:stay_length] ]
        end
      )
    end

    def setup_questions
      {
        q5a_a1: {
          title:  nil,
          value: 'Total number of persons served',
        },
        q5a_a2: {
          title:  nil,
          value: 'Number of adults (age 18 or over)',
        },
        q5a_a3: {
          title:  nil,
          value: 'Number of children (under age 18)',
        },
        q5a_a4: {
          title:  nil,
          value: 'Number of persons with unknown age',
        },
        q5a_a5: {
          title:  nil,
          value: 'Number of leavers',
        },
        q5a_a6: {
          title:  nil,
          value: 'Number of adult leavers',
        },
        q5a_a7: {
          title:  nil,
          value: 'Number of adult and head of household leavers',
        },
        q5a_a8: {
          title:  nil,
          value: 'Number of stayers',
        },
        q5a_a9: {
          title:  nil,
          value: 'Number of adult stayers',
        },
        q5a_a10: {
          title:  nil,
          value: 'Number of veterans',
        },
        q5a_a11: {
          title:  nil,
          value: 'Number of chronically homeless persons',
        },
        q5a_a12: {
          title:  nil,
          value: 'Number of youth under age 25',
        },
        q5a_a13: {
          title:  nil,
          value: 'Number of parenting youth under age 25 with children',
        },
        q5a_a14: {
          title:  nil,
          value: 'Number of adult heads of household',
        },
        q5a_a15: {
          title:  nil,
          value: 'Number of child and unknown-age heads of household',
        },
        q5a_a16: {
          title:  nil,
          value: 'Heads of households and adult stayers in the project 365 days or more',
        },

        q5a_b1: {
          title:  'Total number of persons served',
          value: 0,
        },
        q5a_b2: {
          title:  'Number of adults (age 18 or over)',
          value: 0,
        },
        q5a_b3: {
          title:  'Number of children (under age 18)',
          value: 0,
        },
        q5a_b4: {
          title:  'Number of persons with unknown age',
          value: 0,
        },
        q5a_b5: {
          title:  'Number of leavers',
          value: 0,
        },
        q5a_b6: {
          title:  'Number of adult leavers',
          value: 0,
        },
        q5a_b7: {
          title:  'Number of adult and head of household leavers',
          value: 0,
        },
        q5a_b8: {
          title:  'Number of stayers',
          value: 0,
        },
        q5a_b9: {
          title:  'Number of adult stayers',
          value: 0,
        },
        q5a_b10: {
          title:  'Number of veterans',
          value: 0,
        },
        q5a_b11: {
          title:  'Number of chronically homeless persons',
          value: 0,
        },
        q5a_b12: {
          title:  'Number of youth under age 25',
          value: 0,
        },
        q5a_b13: {
          title:  'Number of parenting youth under age 25 with children',
          value: 0,
        },
        q5a_b14: {
          title:  'Number of adult heads of household',
          value: 0,
        },
        q5a_b15: {
          title:  'Number of child and unknown-age heads of household',
          value: 0,
        },
        q5a_b16: {
          title:  'Heads of households and adult stayers in the project 365 days or more',
          value: 0,
        },
      }
    end

  end
end