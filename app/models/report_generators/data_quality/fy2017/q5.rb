###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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

        add_es_sh_so_answers()

        update_report_progress(percent: 25)

        add_th_answers()

        update_report_progress(percent: 50)

        add_ph_answers()

        update_report_progress(percent: 75)
        add_totals()
        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    def add_es_sh_so_answers
      adult_or_hoh_clients = {}
      project_types = ES + SH + SO
      @es_sh_so_client_ids = client_ids_for_project_types(project_types)
      return unless @es_sh_so_client_ids.any?
      client_personal_ids = personal_ids(@es_sh_so_client_ids)

      @es_sh_so_client_ids.each_slice(250) do |client_ids|
        fetch_clients(project_types, client_ids).each do |client_id, enrollments|
          enrollment = enrollments.last
          adult_or_hoh_clients[client_id] = enrollment if adult?(enrollment[:age]) || head_of_household?(enrollment[:RelationshipToHoH])
        end
      end
      add_issues(field: :q5_b2, clients: adult_or_hoh_clients, personal_ids: client_personal_ids)

      approximate_start_date_issues = date_missing(
        item: :DateToStreetESSH,
        clients: adult_or_hoh_clients
      )
      add_issues(field: :q5_e2, clients: approximate_start_date_issues, personal_ids: client_personal_ids)

      times_homeless_missing_issues = item_missing(
        item: :TimesHomelessPastThreeYears,
        clients: adult_or_hoh_clients
      )
      add_issues_with_times_homeless(field: :q5_f2, clients: times_homeless_missing_issues, personal_ids: client_personal_ids)

      months_homeless_missing_issues = item_missing(
        item: :MonthsHomelessPastThreeYears,
        clients: adult_or_hoh_clients
      )
      add_issues_with_months_homeless(field: :q5_g2, clients: months_homeless_missing_issues, personal_ids: client_personal_ids)

      poor_quality = Set.new
      poor_quality += approximate_start_date_issues.keys
      poor_quality += times_homeless_missing_issues.keys
      poor_quality += months_homeless_missing_issues.keys
      @answers[:q5_h2][:value] = ((poor_quality.size.to_f / adult_or_hoh_clients.count) * 100).round(2)

      @clients_with_issues += poor_quality
    end


    def add_th_answers
      adult_or_hoh_clients = {}
      project_types = TH
      @th_client_ids = client_ids_for_project_types(project_types)
      return unless @th_client_ids.any?
      client_personal_ids = personal_ids(@th_client_ids)

      @th_client_ids.each_slice(250) do |client_ids|
        fetch_clients(project_types, client_ids).each do |client_id, enrollments|
          enrollment = enrollments.last
          adult_or_hoh_clients[client_id] = enrollment if adult?(enrollment[:age]) || head_of_household?(enrollment[:RelationshipToHoH])
        end
      end
      add_issues(field: :q5_b3, clients: adult_or_hoh_clients, personal_ids: client_personal_ids)

      institution_time_issues = issues_with_institution_time(clients: adult_or_hoh_clients)
      add_issues(field: :q5_c3, clients: institution_time_issues, personal_ids: client_personal_ids)

      housing_time_issues = issues_with_housing_time(clients: adult_or_hoh_clients)
      add_issues(field: :q5_d3, clients: housing_time_issues, personal_ids: client_personal_ids)

      approximate_start_date_issues = date_missing(
        item: :DateToStreetESSH,
        clients: adult_or_hoh_clients
      )
      add_issues(field: :q5_e3, clients: approximate_start_date_issues, personal_ids: client_personal_ids)

      times_homeless_missing_issues = item_missing(
        item: :TimesHomelessPastThreeYears,
        clients: adult_or_hoh_clients,
        extra_restrictions: true
      )
      add_issues_with_times_homeless(field: :q5_f3, clients: times_homeless_missing_issues, personal_ids: client_personal_ids)

      months_homeless_missing_issues = item_missing(
        item: :MonthsHomelessPastThreeYears,
        clients: adult_or_hoh_clients,
        extra_restrictions: true
      )
      add_issues_with_months_homeless(field: :q5_g3, clients: months_homeless_missing_issues, personal_ids: client_personal_ids)

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
      adult_or_hoh_clients = {}
      project_types = PH
      @ph_client_ids = client_ids_for_project_types(project_types)
      return unless @ph_client_ids.any?
      client_personal_ids = personal_ids(@ph_client_ids)

      @ph_client_ids.each_slice(250) do |client_ids|
        fetch_clients(project_types, client_ids).each do |client_id, enrollments|
          enrollment = enrollments.last
          adult_or_hoh_clients[client_id] = enrollment if adult?(enrollment[:age]) || head_of_household?(enrollment[:RelationshipToHoH])
        end
      end
      add_issues(field: :q5_b4, clients: adult_or_hoh_clients, personal_ids: client_personal_ids)

      institution_time_issues = issues_with_institution_time(clients: adult_or_hoh_clients)
      add_issues(field: :q5_c4, clients: institution_time_issues, personal_ids: client_personal_ids)

      housing_time_issues = issues_with_housing_time(clients: adult_or_hoh_clients)
      add_issues(field: :q5_d4, clients: housing_time_issues, personal_ids: client_personal_ids)

      approximate_start_date_issues = date_missing(
        item: :DateToStreetESSH,
        clients: adult_or_hoh_clients
      )
      add_issues(field: :q5_e4, clients: approximate_start_date_issues, personal_ids: client_personal_ids)

      times_homeless_missing_issues = item_missing(
        item: :TimesHomelessPastThreeYears,
        clients: adult_or_hoh_clients,
        extra_restrictions: true
      )
      add_issues_with_times_homeless(field: :q5_f4, clients: times_homeless_missing_issues, personal_ids: client_personal_ids)

      months_homeless_missing_issues = item_missing(
        item: :MonthsHomelessPastThreeYears,
        clients: adult_or_hoh_clients,
        extra_restrictions: true
      )
      add_issues_with_months_homeless(field: :q5_g4, clients: months_homeless_missing_issues, personal_ids: client_personal_ids)

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
      all_client_count = @es_sh_so_client_ids.size + @th_client_ids.size + @ph_client_ids.size
      @answers[:q5_b5][:value] = all_client_count
      @answers[:q5_h5][:value] = ((@clients_with_issues.size.to_f / all_client_count) * 100).round(2)
    end

    def add_issues(field:, clients:, personal_ids:)
      @answers[field][:value] = clients.size
      @support[field][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'Project', 'Entry', 'Exit'],
        data: clients.map do |id, enrollment|
          [
            id,
            personal_ids[id].join(', '),
            enrollment[:project_name],
            enrollment[:first_date_in_program],
            enrollment[:last_date_in_program],
          ]
        end
      )
    end

    def add_issues_with_times_homeless(field:, clients:, personal_ids:)
      @answers[field][:value] = clients.size
      @support[field][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'Project', 'Entry', 'Exit', 'Times Homeless Past Three Years'],
        data: clients.map do |id, enrollment|
          [
            id,
            personal_ids[id].join(', '),
            enrollment[:project_name],
            enrollment[:first_date_in_program],
            enrollment[:last_date_in_program],
            HUD.times_homeless_past_three_years(enrollment[:TimesHomelessPastThreeYears]),
          ]
        end
      )
    end

    def add_issues_with_months_homeless(field:, clients:, personal_ids:)
      @answers[field][:value] = clients.size
      @support[field][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'Project', 'Entry', 'Exit', 'Months Homeless Past Three Years'],
        data: clients.map do |id, enrollment|
          [
            id,
            personal_ids[id].join(', '),
            enrollment[:project_name],
            enrollment[:first_date_in_program],
            enrollment[:last_date_in_program],
            HUD.months_homeless_past_three_years(enrollment[:MonthsHomelessPastThreeYears]),
          ]
        end
      )
    end

    def item_missing item:, clients:, extra_restrictions: false
      clients.select do |id, enrollment|
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
      [16,1,18].include?(enrollment[:LivingSituation])
    end

    def previously_institutionalized? enrollment
      [15,6,7,24,4,5].include?(enrollment[:LivingSituation]) &&
      [10,11,2,3].include?(enrollment[:LengthOfStay]) &&
      enrollment[:PreviousStreetESSH] == 1
    end

    def briefly_housed? enrollment
      [29, 14, 2, 32, 36, 35, 28, 19, 3, 31, 33, 34, 10, 20, 21, 11, 8, 9,nil].include?(enrollment[:LivingSituation]) &&
      [10,11].include?(enrollment[:LengthOfStay]) &&
      enrollment[:PreviousStreetESSH] == 1
    end

    def date_missing item:, clients:
      clients.select do |id, enrollment|
        enrollment[item].blank?
      end
    end

    def issues_with_institution_time clients:
      clients.select do |_, enrollment|
        [15,6,7,25,4,5].include?(enrollment[:LivingSituation]) && [8,9,99,nil].include?(enrollment[:LengthOfStay])
      end
    end

    def issues_with_housing_time clients:
      clients.select do |_, enrollment|
        [29, 14, 2, 32, 36, 35, 28, 19, 3, 31, 33, 34, 10, 20, 21, 11, 8, 9, nil].include?(enrollment[:LivingSituation]) && [8,9,99,nil].include?(enrollment[:LengthOfStay])
      end
    end

    def client_batch_scope(project_types)
      active_client_scope.
        distinct.
        hud_project_type(project_types).
        includes(:enrollment).
        joins(:project).
        distinct
    end

    def client_ids_for_project_types(project_types)
      client_batch_scope(project_types).
        pluck(:client_id)
    end

    def fetch_clients(project_types, client_ids)
      client_batch_scope(project_types).
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

    def columns
      @columns ||= {
        client_id: she_t[:client_id],
        age: she_t[:age],
        DOB: c_t[:DOB],
        project_type: she_t[:computed_project_type],
        project_id: she_t[:project_id],
        data_source_id: she_t[:data_source_id],
        first_date_in_program: she_t[:first_date_in_program],
        last_date_in_program: she_t[:last_date_in_program],
        project_name: she_t[:project_name],
        destination: she_t[:destination],
        enrollment_group_id: she_t[:enrollment_group_id],
        LivingSituation: e_t[:LivingSituation],
        LengthOfStay: e_t[:LengthOfStay],
        DateToStreetESSH: e_t[:DateToStreetESSH],
        TimesHomelessPastThreeYears: e_t[:TimesHomelessPastThreeYears],
        MonthsHomelessPastThreeYears: e_t[:MonthsHomelessPastThreeYears],
        PreviousStreetESSH: e_t[:PreviousStreetESSH],
      }
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
