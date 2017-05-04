module ReportGenerators::DataQuality::Fy2016
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
      if start_report(Reports::DataQuality::Fy2016::Q5.first)
        @answers = setup_questions()
        @support = @answers.deep_dup
        @es_sh_so_clients = fetch_clients(ES + SH + SO)
        if @es_sh_so_clients.any?
          @clients_with_issues = Set.new
          add_es_sh_so_answers()
          update_report_progress(percent: 25)
         
        end
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
      @answers[:q5_b2][:value] = adult_or_hoh_clients.size
      @support[:q5_b2][:support] = add_support(
        headers: ['Client ID', 'Project', 'Entry', 'Exit'],
        data: adult_or_hoh_clients.map do |id, enrollments|
          enrollment = enrollments.last
          [
            id, 
            enrollment[:project_name],
            enrollment[:first_date_in_program],
            enrollment[:last_date_in_program],
          ]
        end
      )

      approximate_start_date_issues = issues_with_approximate_start_date(clients: adult_or_hoh_clients)
      @answers[:q5_e2][:value] = approximate_start_date_issues.size
      @support[:q5_e2][:support] = add_support(
        headers: ['Client ID', 'Project', 'Entry', 'Exit'],
        data: approximate_start_date_issues.map do |id, enrollments|
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

    def fetch_clients(project_types)
      columns = {
        client_id: :client_id, 
        age: :age, 
        project_type: act_as_project_overlay, 
        project_id: :project_id, 
        data_source_id: :data_source_id,
        first_date_in_program: :first_date_in_program,
        last_date_in_program: :last_date_in_program,
        project_name: :project_name,
        destination: :destination,
        enrollment_group_id: :enrollment_group_id,
        ResidencePrior: :ResidencePrior,
        ResidencePriorLengthOfStay: :ResidencePriorLengthOfStay,
        DateToStreetESSH: :DateToStreetESSH,
      }
      
      all_client_scope.
        hud_project_type(project_types).
        includes(:enrollment).
        joins(:project).
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