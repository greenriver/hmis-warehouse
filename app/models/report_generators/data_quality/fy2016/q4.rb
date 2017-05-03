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
          @clients_with_issues = Set.new
          add_destination_answers()
          add_income_at_entry_answers()
          update_report_progress(percent: 50)
          add_income_at_exit_answers()
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
      poor_quality = leavers.select do |_, enrollment|
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
      @answers[:q4_c2][:value] = ((counted.size.to_f / leavers.count) * 100).round(2)
    end

    # 2. Column B Row 3 – count the number of adults and heads of household active in the report date range
    # where any one of the following are true:
    #   a. [income and sources] at entry is completely missing.
    #   b. There is no record of [income and sources] with an [information date] equal to [project entry date]
    # and a [data collection stage] of project entry (1).
    #   c. [data collection stage] for [income and sources] = 1 AND [income from any source] = 8, 9, or missing.
    #   d. [data collection stage] for [income and sources] = 1 AND [income from any source] = 0 AND there
    # are identified income sources.
    #   e. [data collection stage] for [income and sources] = 1 AND [income from any source] = 1 AND there are no identified income sources.
    def add_income_at_entry_answers
      client_ids = adult_heads.keys
      
      # This potentially contains more income records than we need
      # since we only care about the most recent enrollment 
      incomes = incomes_by_enrollment(client_ids: client_ids, stage: :entry)
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

    # Column B Row 5 – count the number of adult and head of household leavers where any one of the following are true:
    #   a. There is no record of [income and sources] with an [information date] equal to [project exit date] and a [data collection stage] of project exit (3).
    #   b. [data collection stage] for [income and sources] = 3 AND [income from any source] = 8, 9, or missing.
    #   c. [income from any source] = 0 AND there are identified income sources.
    #   d. [income from any source] = 1 AND there are no identified income sources.
    def add_income_at_exit_answers
      client_ids = adult_heads_of_households.keys
      
      # This potentially contains more income records than we need
      # since we only care about the most recent enrollment 
      incomes = incomes_by_enrollment(client_ids: client_ids, stage: :exit)
      missing = Hash.new
      incorrect_date = Hash.new
      incorrect_any_source = Hash.new
      should_not_have_sources_but_does = Hash.new
      should_have_sources_but_does_not = Hash.new
      client_ids.each do |id|
        enrollment = leavers[id]
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
      @answers[:q4_b5][:value] = poor_quality.size
      @support[:q4_b5][:support] = add_support(
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
      @answers[:q4_c5][:value] = ((poor_quality.size.to_f / (@adults.count + other_heads.count)) * 100).round(2)
    end

    # Column B Row 4 – count the number of adults and heads of household stayers active in the report date range in project stays of >= 365 days as of the [report end date] where any one of the following are true:
    #   a. There is no record of [income and sources] with an [information date] within 30 days of the anniversary date and a [data collection stage] of annual assessment (5).
    #   b. [information date] is within 30 days of the anniversary date AND [data collection stage] for [income and sources] = 5 AND [income from any source] = 8, 9, or missing.
    #   c. [information date] is within 30 days of the anniversary date AND [data collection stage] for [income and sources] = 5 AND [income from any source] = 0 AND there are identified income sources.
    #   d. [information date] is within 30 days of the anniversary date AND [data collection stage] for [income and sources] = 5 AND [income from any source] = 1 AND there are no identified income sources.
    def add_income_annual_update_answers
      all_client_scope.includes(enrollment: :income_benefits_annual_update)
    end

    def incomes_by_enrollment client_ids:, stage:
      stages = {
        entry: :income_benefits_at_entry,
        annual: :income_benefits_annual_update,
        exit: :income_benefits_at_exit,
      }
      columns = income_columns
      [].tap do |m|
        client_ids.each_slice(5000) do |ids|
          m.concat(
            all_client_scope.
              joins(enrollment: stages[stage]).
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
    end

    def income_columns
      @columns ||= begin
        income_source_columns = Hash[income_sources.map{|v| [v,v]}]
        {
          client_id: :client_id, 
          project_id: :project_id, 
          data_source_id: :data_source_id,
          first_date_in_program: :first_date_in_program,
          last_date_in_program: :last_date_in_program,
          project_name: :project_name,
          enrollment_group_id: :enrollment_group_id,
          IncomeFromAnySource: :IncomeFromAnySource,
        }.merge(income_source_columns)        
      end
      @columns
    end

    def income_sources
      [
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