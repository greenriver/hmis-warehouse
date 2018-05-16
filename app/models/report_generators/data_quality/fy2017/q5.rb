module ReportGenerators::DataQuality::Fy2017
  class Q5 < Base
    ADULT = 18
    # PH = [3,9,10,13]
    PH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:ph).flatten(1)
    # TH = [2]
    TH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:th).flatten(1)
    # ES = [1]
    ES = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:es).flatten(1)
    # SH = [8]
    SH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:sh).flatten(1)
    # SO = [4]
    SO = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:so).flatten(1)

    def run!
      if start_report(Reports::DataQuality::Fy2017::Q5.first)
        @answers = setup_questions()
        @support = @answers.deep_dup
        @clients_with_issues = Set.new
        @es_sh_so_clients = fetch_clients(ES + SH + SO)
        if @es_sh_so_clients.any?
          
          add_es_sh_so_answers()
        end
        update_report_progress(percent: 25)
        @th_clients = fetch_clients(TH)
        if @th_clients.any?
          add_th_answers()
        end
        update_report_progress(percent: 50)
        @ph_clients = fetch_clients(PH)
        if @ph_clients.any?
          add_ph_answers()
        end
        update_report_progress(percent: 75)
        add_totals()
        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    def add_es_sh_so_answers
      adult_or_hoh_clients = @es_sh_so_clients.select do |_, enrollments|
        enrollment = enrollments.last
        adult?(enrollment[:age]) || head_of_household?(enrollment[:RelationshipToHoH])
      end
      add_issues(field: :q5_b2, clients: adult_or_hoh_clients)
      
      approximate_start_date_issues = date_missing(
        item: :DateToStreetESSH, 
        clients: adult_or_hoh_clients
      )
      add_issues(field: :q5_e2, clients: approximate_start_date_issues)

      times_homeless_missing_issues = item_missing(
        item: :TimesHomelessPastThreeYears, 
        clients: adult_or_hoh_clients
      )
      add_issues_with_times_homeless(field: :q5_f2, clients: times_homeless_missing_issues)
      
      months_homeless_missing_issues = item_missing(
        item: :MonthsHomelessPastThreeYears, 
        clients: adult_or_hoh_clients
      )
      add_issues_with_months_homeless(field: :q5_g2, clients: months_homeless_missing_issues)
      
      poor_quality = Set.new
      poor_quality += approximate_start_date_issues.keys
      poor_quality += times_homeless_missing_issues.keys
      poor_quality += months_homeless_missing_issues.keys
      @answers[:q5_h2][:value] = ((poor_quality.size.to_f / adult_or_hoh_clients.count) * 100).round(2)

      @clients_with_issues += poor_quality
    end


    def add_th_answers
      adult_or_hoh_clients = @th_clients.select do |_, enrollments|
        enrollment = enrollments.last
        adult?(enrollment[:age]) || head_of_household?(enrollment[:RelationshipToHoH])
      end
      add_issues(field: :q5_b3, clients: adult_or_hoh_clients)
      
      institution_time_issues = issues_with_institution_time(clients: @th_clients)
      add_issues(field: :q5_c3, clients: institution_time_issues)

      housing_time_issues = issues_with_housing_time(clients: @th_clients)
      add_issues(field: :q5_d3, clients: housing_time_issues)

      approximate_start_date_issues = date_missing(
        item: :DateToStreetESSH, 
        clients: adult_or_hoh_clients
      )
      add_issues(field: :q5_e3, clients: approximate_start_date_issues)

      times_homeless_missing_issues = item_missing(
        item: :TimesHomelessPastThreeYears, 
        clients: adult_or_hoh_clients,
        extra_restrictions: true
      )
      add_issues_with_times_homeless(field: :q5_f3, clients: times_homeless_missing_issues)
      
      months_homeless_missing_issues = item_missing(
        item: :MonthsHomelessPastThreeYears, 
        clients: adult_or_hoh_clients,
        extra_restrictions: true
      )
      add_issues_with_months_homeless(field: :q5_g3, clients: months_homeless_missing_issues)
      
      poor_quality = Set.new
      poor_quality += institution_time_issues.keys
      poor_quality += housing_time_issues.keys
      poor_quality += approximate_start_date_issues.keys
      poor_quality += times_homeless_missing_issues.keys
      poor_quality += months_homeless_missing_issues.keys
      @answers[:q5_h3][:value] = ((poor_quality.size.to_f / adult_or_hoh_clients.count) * 100).round(2)

      @clients_with_issues += poor_quality
    end

    def add_ph_answers
      adult_or_hoh_clients = @ph_clients.select do |_, enrollments|
        enrollment = enrollments.last
        adult?(enrollment[:age]) || head_of_household?(enrollment[:RelationshipToHoH])
      end
      add_issues(field: :q5_b4, clients: adult_or_hoh_clients)
      
      institution_time_issues = issues_with_institution_time(clients: @th_clients)
      add_issues(field: :q5_c4, clients: institution_time_issues)

      housing_time_issues = issues_with_housing_time(clients: @th_clients)
      add_issues(field: :q5_d4, clients: housing_time_issues)

      approximate_start_date_issues = date_missing(
        item: :DateToStreetESSH, 
        clients: adult_or_hoh_clients
      )
      add_issues(field: :q5_e4, clients: approximate_start_date_issues)

      times_homeless_missing_issues = item_missing(
        item: :TimesHomelessPastThreeYears, 
        clients: adult_or_hoh_clients,
        extra_restrictions: true
      )
      add_issues_with_times_homeless(field: :q5_f4, clients: times_homeless_missing_issues)
      
      months_homeless_missing_issues = item_missing(
        item: :MonthsHomelessPastThreeYears, 
        clients: adult_or_hoh_clients,
        extra_restrictions: true
      )
      add_issues_with_months_homeless(field: :q5_g4, clients: months_homeless_missing_issues)
      
      poor_quality = Set.new
      poor_quality += institution_time_issues.keys
      poor_quality += housing_time_issues.keys
      poor_quality += approximate_start_date_issues.keys
      poor_quality += times_homeless_missing_issues.keys
      poor_quality += months_homeless_missing_issues.keys
      @answers[:q5_h4][:value] = ((poor_quality.size.to_f / adult_or_hoh_clients.count) * 100).round(2)

      @clients_with_issues += poor_quality
    end

    def add_totals
      all_client_count = @es_sh_so_clients.size + @th_clients.size + @ph_clients.size
      @answers[:q5_b5][:value] = all_client_count
      @answers[:q5_h5][:value] = ((@clients_with_issues.size.to_f / all_client_count) * 100).round(2)
    end

    def add_issues field:, clients:
      @answers[field][:value] = clients.size
      @support[field][:support] = add_support(
        headers: ['Client ID', 'Project', 'Entry', 'Exit'],
        data: clients.map do |id, enrollments|
          enrollment = enrollments.last
          [
            id, 
            enrollment[:project_name],
            enrollment[:first_date_in_program],
            enrollment[:last_date_in_program],
          ]
        end
      )
    end

    def add_issues_with_times_homeless field:, clients:
      @answers[field][:value] = clients.size
      @support[field][:support] = add_support(
        headers: ['Client ID', 'Project', 'Entry', 'Exit', 'Times Homeless Past Three Years'],
        data: clients.map do |id, enrollments|
          enrollment = enrollments.last
          [
            id, 
            enrollment[:project_name],
            enrollment[:first_date_in_program],
            enrollment[:last_date_in_program],
            HUD.times_homeless_past_three_years(enrollment[:TimesHomelessPastThreeYears]),
          ]
        end
      )
    end

    def add_issues_with_months_homeless field:, clients:
      @answers[field][:value] = clients.size
      @support[field][:support] = add_support(
        headers: ['Client ID', 'Project', 'Entry', 'Exit', 'Months Homeless Past Three Years'],
        data: clients.map do |id, enrollments|
          enrollment = enrollments.last
          [
            id, 
            enrollment[:project_name],
            enrollment[:first_date_in_program],
            enrollment[:last_date_in_program],
            HUD.months_homeless_past_three_years(enrollment[:MonthsHomelessPastThreeYears]),
          ]
        end
      )
    end

    def item_missing item:, clients:, extra_restrictions: false
      clients.select do |id, enrollments|
        enrollment = enrollments.last
        should_exist = false
        if extra_restrictions
          should_exist = previously_homeless?(enrollment) || 
            previously_institutionalized?(enrollment) || 
            briefly_housed?(enrollment)
        else
          should_exist = true
        end

        [8,0,99,nil].include?(enrollment[item]) && should_exist
      end
    end

    def previously_homeless? enrollment
      [16,1,18,27].include?(enrollment[:ResidencePrior])
    end

    def previously_institutionalized? enrollment
      [15,6,7,24,4,5].include?(enrollment[:ResidencePrior]) && 
      [10,11,2,3].include?(enrollment[:ResidencePriorLengthOfStay]) &&
      enrollment[:PreviousStreetESSH] == 1
    end

    def briefly_housed? enrollment
      [14,23,21,3,22,19,25,20,26,12,13,2,8,9,99,nil].include?(enrollment[:ResidencePrior]) && 
      [10,11].include?(enrollment[:ResidencePriorLengthOfStay]) &&
      enrollment[:PreviousStreetESSH] == 1
    end

    def date_missing item:, clients:
      clients.select do |id, enrollments|
        enrollment = enrollments.last
        enrollment[item].blank?
      end
    end

    def issues_with_institution_time clients:
      clients.select do |_, enrollments|
        enrollment = enrollments.last
        [15,6,7,24,4,5].include?(enrollment[:ResidencePrior]) && [8,9,99,nil].include?(enrollment[:ResidencePriorLengthOfStay])
      end
    end

    def issues_with_housing_time clients:
      clients.select do |_, enrollments|
        enrollment = enrollments.last
        [14,23,21,3,22,19,25,20,26,12,13,2,8,9].include?(enrollment[:ResidencePrior]) && [8,9,99,nil].include?(enrollment[:ResidencePriorLengthOfStay]) 
      end
    end


    def fetch_clients(project_types)
      et = GrdaWarehouse::Hud::Enrollment.arel_table
      ct = GrdaWarehouse::Hud::Client.arel_table
      sh_t = GrdaWarehouse::ServiceHistory.arel_table
      columns = {
        client_id: sh_t[:client_id].as('client_id').to_sql, 
        age: sh_t[:age].as('age').to_sql,
        DOB: ct[:DOB].as('DOB').to_sql,
        project_type: act_as_project_overlay, 
        project_id: sh_t[:project_id].as('project_id').to_sql,
        data_source_id: sh_t[:data_source_id].as('data_source_id').to_sql,
        first_date_in_program: sh_t[:first_date_in_program].as('first_date_in_program').to_sql,
        last_date_in_program: sh_t[:last_date_in_program].as('last_date_in_program').to_sql,
        project_name: sh_t[:project_name].as('project_name').to_sql,
        destination: sh_t[:destination].as('destination').to_sql,
        enrollment_group_id: sh_t[:enrollment_group_id].as('enrollment_group_id').to_sql, 
        ResidencePrior: et[:ResidencePrior].as('ResidencePrior').to_sql,
        ResidencePriorLengthOfStay: et[:ResidencePriorLengthOfStay].as('ResidencePriorLengthOfStay').to_sql,
        DateToStreetESSH: et[:DateToStreetESSH].as('DateToStreetESSH').to_sql,
        TimesHomelessPastThreeYears: et[:TimesHomelessPastThreeYears].as('TimesHomelessPastThreeYears').to_sql,
        MonthsHomelessPastThreeYears: et[:MonthsHomelessPastThreeYears].as('MonthsHomelessPastThreeYears').to_sql,
        PreviousStreetESSH: et[:PreviousStreetESSH].as('PreviousStreetESSH').to_sql,
      }
      
      all_client_scope.
        hud_project_type(project_types).
        includes(:enrollment).
        joins(:project).
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

    def setup_questions
      {
        q5_a1: {
          title:  nil,
          value: 'Entering into project type',
        },
        q5_b1: {
          title:  nil,
          value: 'Count of total records',
        },
        q5_c1: {
          title:  nil,
          value: 'Missing time in institution (3.917.2)',
        },
        q5_d1: {
          title:  nil,
          value: 'Missing time in housing (3.917.2)',
        },
        q5_e1: {
          title:  nil,
          value: 'Approximate Date started (3.917.3) DK/R/missing',
        },
        q5_f1: {
          title:  nil,
          value: 'Number of times (3.917.4) DK/R/missing',
        },
        q5_g1: {
          title:  nil,
          value: 'Number of months (3.917.5) DK/R/missing',
        },
        q5_h1: {
          title:  nil,
          value: '% of records unable to calculate',
        },
        q5_b2: {
          title:  'ES, SH, Street Outreach - Count of total records',
          value: 0,
        },
        q5_e2: {
          title:  'ES, SH, Street Outreach - Approximate Date started (3.917.3) DK/R/missing',
          value: 0,
        },
        q5_f2: {
          title:  'ES, SH, Street Outreach - Number of times (3.917.4) DK/R/missing',
          value: 0,
        },
        q5_g2: {
          title:  'ES, SH, Street Outreach - Number of months (3.917.5) DK/R/missing',
          value: 0,
        },
        q5_h2: {
          title:  'ES, SH, Street Outreach - % of records unable to calculate',
          value: 0,
        },
        q5_b3: {
          title:  'TH - Count of total records',
          value: 0,
        },
        q5_c3: {
          title:  'TH - Missing time in institution (3.917.2)',
          value: 0,
        },
        q5_d3: {
          title:  'TH - Missing time in housing (3.917.2)',
          value: 0,
        },
        q5_e3: {
          title:  'TH - Approximate Date started (3.917.3) DK/R/missing',
          value: 0,
        },
        q5_f3: {
          title:  'TH - Number of times (3.917.4) DK/R/missing',
          value: 0,
        },
        q5_g3: {
          title:  'TH - Number of months (3.917.5) DK/R/missing',
          value: 0,
        },
        q5_h3: {
          title:  'TH - % of records unable to calculate',
          value: 0,
        },
        q5_b4: {
          title:  'PH (all) - Count of total records',
          value: 0,
        },
        q5_c4: {
          title:  'PH (all) - Missing time in institution (3.917.2)',
          value: 0,
        },
        q5_d4: {
          title:  'PH (all) - Missing time in housing (3.917.2)',
          value: 0,
        },
        q5_e4: {
          title:  'PH (all) - Approximate Date started (3.917.3) DK/R/missing',
          value: 0,
        },
        q5_f4: {
          title:  'PH (all) - Number of times (3.917.4) DK/R/missing',
          value: 0,
        },
        q5_g4: {
          title:  'PH (all) - Number of months (3.917.5) DK/R/missing',
          value: 0,
        },
        q5_h4: {
          title:  'PH (all) - % of records unable to calculate',
          value: 0,
        },
        q5_b5: {
          title:  'Total - Count of total records',
          value: 0,
        },
        q5_h5: {
          title:  'Total - % of records unable to calculate',
          value: 0,
        },
      }
    end
  end
end