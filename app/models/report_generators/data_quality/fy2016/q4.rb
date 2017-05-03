module ReportGenerators::DataQuality::Fy2016
  class Q4 < Base
    ADULT = 18

    def run!
      if start_report(Reports::DataQuality::Fy2016::Q4.first)
        @answers = setup_questions()
        @support = @answers.deep_dup
        @all_clients = fetch_all_clients()
        if @all_clients.any?
          setup_age_categories()
          update_report_progress(percent: 25)
          @leavers = calculate_leavers()
          update_report_progress(percent: 50)
          @stayers = calculate_stayers()
          @clients_with_issues = Set.new
          add_destination_answers()
          add_income_at_entry_answers()
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
        project_id: :project_id, 
        data_source_id: :data_source_id,
        first_date_in_program: :first_date_in_program,
        last_date_in_program: :last_date_in_program,
        project_name: :project_name,
        destination: :destination,
        enrollment_group_id: :enrollment_group_id,
      }
      
      all_client_scope.
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

    def add_destination_answers
      counted = Set.new # Only count each client once
      poor_quality = @leavers.select do |_, enrollment|
        [8,9,30,99,nil].include?(enrollment[:destination])
      end
      counted += poor_quality.keys
      @clients_with_issues += poor_quality.keys
      @answers[:q4_b2][:value] = poor_quality.size
      @support[:q4_b2][:support] = add_support(
        headers: ['Client ID', 'Project', 'Entry', 'Exit', 'Destination'],
        data: poor_quality.map do |id, enrollment|
          [
            id, 
            enrollment[:project_name],
            enrollment[:first_date_in_program],
            enrollment[:last_date_in_program],
            HUD.destination(enrollment[:destination]),
          ]
        end
      )
      @answers[:q4_c2][:value] = ((counted.size.to_f / @leavers.count) * 100).round(2)
    end

    def add_income_at_entry_answers
      columns = {
        client_id: :client_id, 
        project_id: :project_id, 
        data_source_id: :data_source_id,
        first_date_in_program: :first_date_in_program,
        last_date_in_program: :last_date_in_program,
        project_name: :project_name,
        enrollment_group_id: :enrollment_group_id,
        IncomeFromAnySource: :IncomeFromAnySource,
        Earned: :Earned,
        Unemployment: :Unemployment,
        SSI: :SSI,
        SSDI: :SSDI,
        VADisabilityService: :VADisabilityService,
        VADisabilityNonService: :VADisabilityNonService,
        PrivateDisability: :PrivateDisability,
        WorkersComp: :WorkersComp,
        TANF: :TANF,
        GA: :GA,
        SocSecRetirement: :SocSecRetirement,
        Pension: :Pension,
        ChildSupport: :ChildSupport,
        Alimony: :Alimony,
        OtherIncomeSource: :OtherIncomeSource,
      }
      client_ids = adult_heads.keys
      
      # This potentially contains more income records than we need
      # since we only care about the most recent enrollment 
      incomes = [].tap do |m|
        client_ids.each_slice(5000) do |ids|
          m.concat(
            all_client_scope.
              joins(enrollment: :income_benefits_at_entry).
              where(client_id: ids).
              pluck(*columns.values).map do |row|
                Hash[columns.keys.zip(row)]
              end
          )
        end
      end.index_by do |income|
        [
          income[:client_id], 
          income[:enrollment_group_id], 
          income[:project_id], 
          income[:data_source_id]
        ]
      end
      missing = Hash.new
      incorrect_date = Hash.new
      incorrect_any_source = Hash.new
      should_not_have_sources_but_does = Hash.new
      should_have_sources_but_does_not = Hash.new
      client_ids.each do |id|
        enrollment = @all_clients[id].last
        if incomes[[
          enrollment[:client_id], 
          enrollment[:enrollment_group_id], 
          enrollment[:project_id], 
          enrollment[:data_source_id],
        ]].blank?
          missing[id] = enrollment
        else
          income = incomes[[
            enrollment[:client_id], 
            enrollment[:enrollment_group_id], 
            enrollment[:project_id], 
            enrollment[:data_source_id]
          ]]
          if enrollment[:first_date_in_program] != income[:first_date_in_program]
            incorrect_date[id] = enrollment
          elsif [8,9,99,nil].include?(income[:IncomeFromAnySource])
            incorrect_any_source[id] = enrollment
          else
            income_sources = [
              :Earned,
              :Unemployment,
              :SSI,
              :SSDI,
              :VADisabilityService,
              :VADisabilityNonService,
              :PrivateDisability,
              :WorkersComp,
              :TANF,
              :GA,
              :SocSecRetirement,
              :Pension,
              :ChildSupport,
              :Alimony,
              :OtherIncomeSource,
            ]
            if income[:IncomeFromAnySource] == 0
              if income.values_at(*income_sources).compact.uniq != [nil]
                should_not_have_sources_but_does[id] = enrollment
              end
            elsif income[:IncomeFromAnySource] == 1
              if income.values_at(*income_sources).compact.uniq == [nil]
                should_have_sources_but_does_not[id] = enrollment
              end
            end
          end
        end
      end
      @clients_with_issues += missing.keys
      @clients_with_issues += incorrect_date.keys
      @clients_with_issues += incorrect_any_source.keys
      @clients_with_issues += should_not_have_sources_but_does.keys
      @clients_with_issues += should_have_sources_but_does_not.keys
      poor_quality = missing.merge(incorrect_date).
        merge(incorrect_any_source).
        merge(should_not_have_sources_but_does).
        merge(should_have_sources_but_does_not)
      @answers[:q4_b3][:value] = poor_quality.size
      @support[:q4_b3][:support] = add_support(
        headers: ['Client ID', 'Project', 'Entry', 'Exit'],
        data: poor_quality.map do |id, enrollment|
          [
            id, 
            enrollment[:project_name],
            enrollment[:first_date_in_program],
            enrollment[:last_date_in_program],
          ]
        end
      )
      @answers[:q4_c3][:value] = ((poor_quality.size.to_f / (@adults.count + other_heads.count)) * 100).round(2)
    end

    def add_income_annual_update_answers
      all_client_scope.includes(enrollment: :income_benefits_annual_update)
    end

    def add_income_at_exit_answers
      all_client_scope.includes(enrollment: :income_benefits_at_exit)
    end

    def setup_questions
      {
        q4_a1: {
          title:  nil,
          value: 'Data Element',
        },
        q4_b1: {
          title:  nil,
          value: 'Error Count',
        },
        q4_c1: {
          title:  nil,
          value: '% of Error Rate',
        },
        q4_a2: {
          title:  nil,
          value: 'Destination (3.12)',
        },
        q4_a3: {
          title:  nil,
          value: 'Income and Sources (4.2) at Entry',
        },
        q4_a4: {
          title:  nil,
          value: 'Income and Sources (4.2) at Annual Assessment',
        },
        q4_a5: {
          title:  nil,
          value: 'Income and Sources (4.2) at Exit',
        },
        q4_b2: {
          title:  'Destination (3.12) - Error Count',
          value: 0,
        },
        q4_c2: {
          title:  'Destination (3.12) - % of Error Rate',
          value: 0,
        },
        q4_b3: {
          title:  'Income and Sources (4.2) at Entry - Error Count',
          value: 0,
        },
        q4_c3: {
          title:  'Income and Sources (4.2) at Entry - % of Error Rate',
          value: 0,
        },
        q4_b4: {
          title:  'Income and Sources (4.2) at Annual Assessment - Error Rate',
          value: 0,
        },
        q4_c4: {
          title:  'Income and Sources (4.2) at Annual Assessment - % of Error Rate',
          value: 0,
        },
        q4_b5: {
          title:  'Income and Sources (4.2) at Exit - Error Rate',
          value: 0,
        },
        q4_c5: {
          title:  'Income and Sources (4.2) at Exit - % of Error Rate',
          value: 0,
        },
      }
    end

  end
end