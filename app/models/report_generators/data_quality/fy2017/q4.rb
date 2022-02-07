###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ReportGenerators::DataQuality::Fy2017
  class Q4 < Base
    ADULT = 18

    def run!
      if start_report(Reports::DataQuality::Fy2017::Q4.first)
        @answers = setup_questions()
        @support = @answers.deep_dup
        @all_client_ids = fetch_all_client_ids()
        @client_personal_ids = personal_ids(@all_client_ids)
        if @all_client_ids.any?
          @clients_with_issues = Set.new
          setup_age_categories(@all_client_ids)
          update_report_progress(percent: 25)
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

    def fetch_all_client_ids
      client_batch_scope.
        pluck(:client_id)
    end

    def client_batch_scope
      active_client_scope.
        distinct.
        includes(:enrollment).
        joins(:project)
    end

    def client_batch(client_ids)
      client_batch_scope.
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
        enrollment_group_id: she_t[:enrollment_group_id],
        project_id: she_t[:project_id],
        data_source_id: she_t[:data_source_id],
        first_date_in_program: she_t[:first_date_in_program],
        last_date_in_program: she_t[:last_date_in_program],
        project_name: she_t[:project_name],
        destination: she_t[:destination],
      }
    end

    def add_destination_answers
      counted = Set.new # Only count each client once
      poor_quality = leavers.select do |_, enrollment|
        [8,9,30,nil].include?(enrollment[:destination])
      end
      counted += poor_quality.keys
      client_personal_ids = personal_ids(counted)

      @clients_with_issues += poor_quality.keys
      @answers[:q4_b2][:value] = poor_quality.size
      @support[:q4_b2][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'Project', 'Entry', 'Exit', 'Destination'],
        data: poor_quality.map do |id, enrollment|
          [
            id,
            client_personal_ids[id].join(', '),
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
      client_personal_ids = personal_ids(client_ids)

      # This potentially contains more income records than we need
      # since we only care about the most recent enrollment
      poor_quality = Hash.new
      client_ids.each_slice(BATCH_SIZE) do |ids|
        incomes = incomes_by_enrollment(client_ids: ids, stage: :entry)
        client_batch(ids).each do |client_id, enrollments|
          enrollment = enrollments.last
          if incomes[[
            enrollment[:client_id],
            enrollment[:enrollment_group_id],
            enrollment[:project_id],
            enrollment[:data_source_id],
          ]].blank?
            enrollment[:reason] = 'Missing income assessment'
            poor_quality[client_id] = enrollment
          else
            income = incomes[[
              enrollment[:client_id],
              enrollment[:enrollment_group_id],
              enrollment[:project_id],
              enrollment[:data_source_id]
            ]].last
            if enrollment[:first_date_in_program] != income[:first_date_in_program]
              enrollment[:reason] = 'Missing income assessment on entry date'
              poor_quality[client_id] = enrollment
            elsif [8,9,nil].include?(income[:IncomeFromAnySource])
              enrollment[:reason] = 'Income from any source refused or missing'
              poor_quality[client_id] = enrollment
            else
              if income[:IncomeFromAnySource] == 0
                if income.values_at(*income_sources).compact.uniq != [nil]
                  enrollment[:reason] = 'Indicated no sources, yet sources exits'
                  poor_quality[client_id] = enrollment
                end
              elsif income[:IncomeFromAnySource] == 1
                if income.values_at(*income_sources).compact.uniq == [nil]
                  enrollment[:reason] = 'Indicated sources, yet no sources exits'
                  poor_quality[client_id] = enrollment
                end
              end
            end
          end
        end
      end
      @clients_with_issues += poor_quality.keys

      @answers[:q4_b3][:value] = poor_quality.size
      @support[:q4_b3][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'Project', 'Entry', 'Exit', 'Reason'],
        data: poor_quality.map do |id, enrollment|
          [
            id,
            client_personal_ids[id].join(', '),
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
      client_personal_ids = personal_ids(client_ids)

      # This potentially contains more income records than we need
      # since we only care about the most recent enrollment
      poor_quality = Hash.new
      client_ids.each_slice(BATCH_SIZE) do |ids|
        incomes = incomes_by_enrollment(client_ids: ids, stage: :exit)
        ids.each do |id|
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
            elsif [8,9,nil].include?(income[:IncomeFromAnySource])
              enrollment[:reason] = 'Income from any source refused or missing'
              poor_quality[id] = enrollment
            else
              if income[:IncomeFromAnySource] == 0
                if income.values_at(*income_sources).compact.uniq != [nil]
                  enrollment[:reason] = 'Indicated no sources, yet sources exits'
                  poor_quality[id] = enrollment
                end
              elsif income[:IncomeFromAnySource] == 1
                if income.values_at(*income_sources).compact.uniq == [nil]
                  enrollment[:reason] = 'Indicated sources, yet no sources exits'
                  poor_quality[id] = enrollment
                end
              end
            end
          end
        end
      end
      @clients_with_issues += poor_quality.keys

      @answers[:q4_b5][:value] = poor_quality.size
      @support[:q4_b5][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'Project', 'Entry', 'Exit', 'Reason'],
        data: poor_quality.map do |id, enrollment|
          [
            id,
            client_personal_ids[id].join(', '),
            enrollment[:project_name],
            enrollment[:first_date_in_program],
            enrollment[:last_date_in_program],
            enrollment[:reason],
          ]
        end
      )
      @answers[:q4_c5][:value] = ((poor_quality.size.to_f / adult_leavers_and_heads_of_household_leavers.count) * 100).round(2)
    end

    # Column B Row 4 – count the number of adults and heads of household stayers active in the report date
    # range who are expected to have an annual assessment as described under Annual Assessment, AND where any one of the following are true:
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

      client_personal_ids = personal_ids(clients_with_enrollments.keys)

      poor_quality = Hash.new
      clients_with_enrollments.keys.each_slice(BATCH_SIZE) do |client_ids|
        incomes = incomes_by_enrollment(client_ids: client_ids, stage: :annual)
        client_batch = clients_with_enrollments.select{ |k,_| client_ids.include?(k) }
        client_batch.each do |id, enrollment|
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
              if [8,9,nil].include?(income[:IncomeFromAnySource])
                enrollment[:reason] = 'Income from any source refused or missing'
                poor_quality[id] = enrollment
              else
                if income[:IncomeFromAnySource] == 0
                  if income.values_at(*income_sources).compact.uniq != [nil]
                    enrollment[:reason] = 'Indicated no sources, yet sources exits'
                    poor_quality[id] = enrollment
                  end
                elsif income[:IncomeFromAnySource] == 1
                  if income.values_at(*income_sources).compact.uniq == [nil]
                    enrollment[:reason] = 'Indicated sources, yet no sources exits'
                    poor_quality[id] = enrollment
                  end
                end
              end
            end
          end
        end
      end
      @clients_with_issues += poor_quality.keys

      @answers[:q4_b4][:value] = poor_quality.size
      @support[:q4_b4][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'Project', 'Entry', 'Exit', 'Reason'],
        data: poor_quality.map do |id, enrollment|
          [
            id,
            client_personal_ids[id].join(', '),
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
      [].tap do |m|
        client_ids.each_slice(5000) do |ids|
          m.concat(
            active_client_scope.
              joins(enrollment: stages[stage]).
              where(client_id: ids).
              merge(GrdaWarehouse::Hud::IncomeBenefit.order(InformationDate: :asc)).
              pluck(*income_columns.values).map do |row|
                Hash[income_columns.keys.zip(row)]
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
      @income_columns ||= begin
        income_source_columns = Hash[income_sources.map{|v| [v, ib_t[v].as(v.to_s)]}]
        {
          client_id: she_t[:client_id],
          project_id: she_t[:project_id],
          data_source_id: she_t[:data_source_id],
          first_date_in_program: she_t[:first_date_in_program],
          last_date_in_program: she_t[:last_date_in_program],
          project_name: she_t[:project_name],
          InformationDate: ib_t[:InformationDate],
          enrollment_group_id: she_t[:enrollment_group_id],
          IncomeFromAnySource: ib_t[:IncomeFromAnySource],
        }.merge(income_source_columns)
      end
      @income_columns
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
