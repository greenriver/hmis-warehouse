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
          update_report_progress(percent: 75)
          add_income_annual_update_answers()
        end
        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    def fetch_all_clients
      ct = GrdaWarehouse::Hud::Client.arel_table
      sh_t = GrdaWarehouse::ServiceHistory.arel_table
      columns = {
        client_id: sh_t[:client_id].as('client_id').to_sql, 
        age: sh_t[:age].as('age').to_sql,
        DOB: ct[:DOB].as('DOB').to_sql,
        project_type: act_as_project_overlay, 
        enrollment_group_id: sh_t[:enrollment_group_id].as('enrollment_group_id').to_sql, 
        project_id: sh_t[:project_id].as('project_id').to_sql, 
        data_source_id: sh_t[:data_source_id].as('data_source_id').to_sql,
        first_date_in_program: sh_t[:first_date_in_program].as('first_date_in_program').to_sql,
        last_date_in_program: sh_t[:last_date_in_program].as('last_date_in_program').to_sql,
        project_name: sh_t[:project_name].as('project_name').to_sql,
        destination: sh_t[:destination].as('destination').to_sql,
      }
      
      all_client_scope.
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
      client_ids = (@adults.keys + other_heads.keys).uniq
      
      # This potentially contains more income records than we need
      # since we only care about the most recent enrollment 
      incomes = incomes_by_enrollment(client_ids: client_ids, stage: :entry)
      poor_quality = Hash.new
      client_ids.each do |id|
        enrollment = @all_clients[id].last
        if incomes[[
          enrollment[:client_id], 
          enrollment[:enrollment_group_id], 
          enrollment[:project_id], 
          enrollment[:data_source_id],
        ]].blank?
          enrollment[:reason] = 'Missing income assessment'
          poor_quality[id] = enrollment
        else
          income = incomes[[
            enrollment[:client_id], 
            enrollment[:enrollment_group_id], 
            enrollment[:project_id], 
            enrollment[:data_source_id]
          ]].last
          if enrollment[:first_date_in_program] != income[:first_date_in_program]
            enrollment[:reason] = 'Missing income assessment on entry date'
            poor_quality[id] = enrollment
          elsif [8,9,99,nil].include?(income[:IncomeFromAnySource])
            enrollment[:reason] = 'Income from any source refused or missing'
            poor_quality[id] = enrollment
          else
            if income[:IncomeFromAnySource] == 0
              if income.values_at(*income_sources).compact.uniq != [nil]  # FIXME? the compact will get rid of nils, so I think this will always be false
                enrollment[:reason] = 'Indicated no sources, yet sources exits'
                poor_quality[id] = enrollment
              end
            elsif income[:IncomeFromAnySource] == 1
              if income.values_at(*income_sources).compact.uniq == [nil]  # see above
                enrollment[:reason] = 'Indicated sources, yet no sources exits'
                poor_quality[id] = enrollment
              end
            end
          end
        end
      end
      @clients_with_issues += poor_quality.keys
      
      @answers[:q4_b3][:value] = poor_quality.size
      @support[:q4_b3][:support] = add_support(
        headers: ['Client ID', 'Project', 'Entry', 'Exit', 'Reason'],
        data: poor_quality.map do |id, enrollment|
          [
            id, 
            enrollment[:project_name],
            enrollment[:first_date_in_program],
            enrollment[:last_date_in_program],
            enrollment[:reason],
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
      client_ids = adult_leavers_and_heads_of_household_leavers.keys
      
      # This potentially contains more income records than we need
      # since we only care about the most recent enrollment 
      incomes = incomes_by_enrollment(client_ids: client_ids, stage: :exit)
      poor_quality = Hash.new
      client_ids.each do |id|
        enrollment = leavers[id]
        if incomes[[
          enrollment[:client_id], 
          enrollment[:enrollment_group_id], 
          enrollment[:project_id], 
          enrollment[:data_source_id],
        ]].blank?
          enrollment[:reason] = 'Missing income assessment'
          poor_quality[id] = enrollment
        else
          income = incomes[[
            enrollment[:client_id], 
            enrollment[:enrollment_group_id], 
            enrollment[:project_id], 
            enrollment[:data_source_id]
          ]].last
          if enrollment[:last_date_in_program] != income[:last_date_in_program]
            enrollment[:reason] = 'Missing income assessment on exit date'
            poor_quality[id] = enrollment
          elsif [8,9,99,nil].include?(income[:IncomeFromAnySource])
            enrollment[:reason] = 'Income from any source refused or missing'
            poor_quality[id] = enrollment
          else
            if income[:IncomeFromAnySource] == 0
              if income.values_at(*income_sources).compact.uniq != [nil]  # see above
                enrollment[:reason] = 'Indicated no sources, yet sources exits'
                poor_quality[id] = enrollment
              end
            elsif income[:IncomeFromAnySource] == 1
              if income.values_at(*income_sources).compact.uniq == [nil]  # see above
                enrollment[:reason] = 'Indicated sources, yet no sources exits'
                poor_quality[id] = enrollment
              end
            end
          end
        end
      end
      @clients_with_issues += poor_quality.keys
      
      @answers[:q4_b5][:value] = poor_quality.size
      @support[:q4_b5][:support] = add_support(
        headers: ['Client ID', 'Project', 'Entry', 'Exit', 'Reason'],
        data: poor_quality.map do |id, enrollment|
          [
            id, 
            enrollment[:project_name],
            enrollment[:first_date_in_program],
            enrollment[:last_date_in_program],
            enrollment[:reason],
          ]
        end
      )
      @answers[:q4_c5][:value] = ((poor_quality.size.to_f / adult_leavers_and_heads_of_household_leavers.count) * 100).round(2)
    end

    # Column B Row 4 – count the number of adults and heads of household stayers active in the report date range in project stays of >= 365 days as of the [report end date] where any one of the following are true:
    #   a. There is no record of [income and sources] with an [information date] within 30 days of the anniversary date and a [data collection stage] of annual assessment (5).
    #   b. [information date] is within 30 days of the anniversary date AND [data collection stage] for [income and sources] = 5 AND [income from any source] = 8, 9, or missing.
    #   c. [information date] is within 30 days of the anniversary date AND [data collection stage] for [income and sources] = 5 AND [income from any source] = 0 AND there are identified income sources.
    #   d. [information date] is within 30 days of the anniversary date AND [data collection stage] for [income and sources] = 5 AND [income from any source] = 1 AND there are no identified income sources.
    def add_income_annual_update_answers
      clients_with_enrollments = adult_stayers_and_heads_of_household_stayers.map do |id, enrollment|
        enrollment[:stay_length] = stay_length(client_id: id, entry_date: enrollment[:first_date_in_program], enrollment_group_id: enrollment[:enrollment_group_id])
        [id,enrollment]
      end.to_h.select do |_,enrollment|
        enrollment[:stay_length] >= 365
      end

      incomes = incomes_by_enrollment(client_ids: clients_with_enrollments.keys, stage: :annual)

      poor_quality = Hash.new
      clients_with_enrollments.each do |id, enrollment|
        if incomes[[
          enrollment[:client_id], 
          enrollment[:enrollment_group_id], 
          enrollment[:project_id], 
          enrollment[:data_source_id],
        ]].blank?
          enrollment[:reason] = 'Missing income assessment'
          poor_quality[id] = enrollment
        else
          anniversary = anniversary_date(enrollment[:first_date_in_program])
          anniversary_incomes = incomes[[
            enrollment[:client_id], 
            enrollment[:enrollment_group_id], 
            enrollment[:project_id], 
            enrollment[:data_source_id]
          ]].select do |income|
            (income[:InformationDate] - anniversary).abs > 30
          end
          if anniversary_incomes.empty?
            enrollment[:reason] = 'Missing income assessment on or near anniversary date'
            poor_quality[id] = enrollment
          else
            income = anniversary_incomes.last
            if [8,9,99,nil].include?(income[:IncomeFromAnySource])
              enrollment[:reason] = 'Income from any source refused or missing'
              poor_quality[id] = enrollment
            else
              if income[:IncomeFromAnySource] == 0
                if income.values_at(*income_sources).compact.uniq != [nil]  # see above
                  enrollment[:reason] = 'Indicated no sources, yet sources exist'
                  poor_quality[id] = enrollment
                end
              elsif income[:IncomeFromAnySource] == 1
                if income.values_at(*income_sources).compact.uniq == [nil]  # FIXME same as above
                  enrollment[:reason] = 'Indicated sources, yet no sources exist'
                  poor_quality[id] = enrollment
                end
              end
            end
          end
        end
      end
      @clients_with_issues += poor_quality.keys

      @answers[:q4_b4][:value] = poor_quality.size
      @support[:q4_b4][:support] = add_support(
        headers: ['Client ID', 'Project', 'Entry', 'Exit', 'Reason'],
        data: poor_quality.map do |id, enrollment|
          [
            id, 
            enrollment[:project_name],
            enrollment[:first_date_in_program],
            enrollment[:last_date_in_program],
            enrollment[:reason],
          ]
        end
      )
      @answers[:q4_c4][:value] = ((poor_quality.size.to_f / clients_with_enrollments.count) * 100).round(2)
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
              merge(GrdaWarehouse::Hud::IncomeBenefit.order(InformationDate: :asc)).
              pluck(*columns.values).map do |row|
                Hash[columns.keys.zip(row)]
              end
          )
        end
      end.group_by do |income|
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
        ct = GrdaWarehouse::Hud::Client.arel_table
        sh_t = GrdaWarehouse::ServiceHistory.arel_table
        it = GrdaWarehouse::Hud::IncomeBenefit.arel_table
        income_source_columns = Hash[income_sources.map{|v| [v, it[v].as(v.to_s).to_sql]}]
        {
          client_id: sh_t[:client_id].as('client_id').to_sql, 
          project_id: sh_t[:project_id].as('project_id').to_sql, 
          data_source_id: sh_t[:data_source_id].as('data_source_id').to_sql,
          first_date_in_program: sh_t[:first_date_in_program].as('first_date_in_program').to_sql,
          last_date_in_program: sh_t[:last_date_in_program].as('last_date_in_program').to_sql,
          project_name: sh_t[:project_name].as('project_name').to_sql, 
          InformationDate: it[:InformationDate].as('InformationDate').to_sql,
          enrollment_group_id: sh_t[:enrollment_group_id].as('enrollment_group_id').to_sql,
          IncomeFromAnySource: it[:IncomeFromAnySource].as('IncomeFromAnySource').to_sql,
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