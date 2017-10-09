module ReportGenerators::CAPER::Fy2017
  # Data Quality: Income and Housing Data Quality
  # this is more or less equivalent to the fy2016 data quality question q4
  class Q6c < Base

    def run!
      if start_report(Reports::CAPER::Fy2017::Q6c.first)
        @answers = setup_questions
        @support = @answers.deep_dup
        @all_clients = fetch_all_clients
        update_report_progress percent: 40
        if @all_clients.any?
          setup_age_categories
          update_report_progress percent: 60
          @clients_with_issues = Set.new
          data_methods = %i[
            destination_answers
            income_at_entry_answers
            income_at_exit_answers
            income_annual_update_answers
          ]
          data_methods.each_with_index do |method, i|
            send("add_#{method}")
            if i < data_methods.length - 1
              update_report_progress percent: 60 + ( 40 * i.to_f / data_methods.length ).round
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
        # age:                   sh_t, # commented this out as redundant given processing below
        client_id:             sh_t,
        data_source_id:        sh_t,
        destination:           sh_t,
        enrollment_group_id:   sh_t,
        first_date_in_program: sh_t,
        last_date_in_program:  sh_t,
        project_id:            sh_t, 
        project_name:          sh_t,
        DOB: c_t,
      ).merge({
        project_type: act_as_project_overlay
      })

      all_client_scope.
        includes(:enrollment).
        joins(:project).
        order(date: :asc).
        pluck(*columns.values).
        map do |row|
          Hash[columns.keys.zip(row)]
        end.each do |enrollment|
          enrollment[:age] = age_for_report(dob: enrollment[:DOB], enrollment: enrollment)
        end.group_by do |row|
          row[:client_id]
        end
    end

    def add_destination_answers
      poor_quality = leavers.select do |_, enrollment|
        [8,9,30,99,nil].include?(enrollment[:destination])
      end
      @clients_with_issues += poor_quality.keys
      @answers[:q6c_b2][:value] = poor_quality.size
      @support[:q6c_b2][:support] = add_support(
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
      @answers[:q6c_c2][:value] = ((poor_quality.size.to_f / leavers.count) * 100).round(2)
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


    def incomes_by_enrollment client_ids:, stage:
      stages = {
        entry:  :income_benefits_at_entry,
        annual: :income_benefits_annual_update,
        exit:   :income_benefits_at_exit,
      }

      columns = columnize(
        **income_sources.map{ |c| [ c, ib_t ] }.to_h,
        IncomeFromAnySource: ib_t,
        InformationDate:     ib_t,
        client_id:             sh_t,
        data_source_id:        sh_t,
        enrollment_group_id:   sh_t,
        first_date_in_program: sh_t,
        last_date_in_program:  sh_t,
        project_id:            sh_t,
        project_name:          sh_t,
      )

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
        income.values_at :client_id, :enrollment_group_id, :project_id, :data_source_id
      end
    end

    def aggregate_incomes(client_ids, incomes)
      poor_quality = {}
      client_ids.each do |id|
        enrollment = @all_clients[id].last
        income     = incomes[
          enrollment.values_at :client_id, :enrollment_group_id, :project_id, :data_source_id
        ]&.first
        if income.blank?
          enrollment[:reason] = 'Missing income assessment'
          poor_quality[id] = enrollment
        else
          if enrollment[:first_date_in_program] != income[:first_date_in_program]
            enrollment[:reason] = 'Missing income assessment on entry date'
            poor_quality[id] = enrollment
          elsif [8,9,99,nil].include?(income[:IncomeFromAnySource])
            enrollment[:reason] = 'Income from any source refused or missing'
            poor_quality[id] = enrollment
          else
            if income[:IncomeFromAnySource] == 0
              if income.values_at(*income_sources).any?
                enrollment[:reason] = 'Indicated no sources, yet sources exist'
                poor_quality[id] = enrollment
              end
            elsif income[:IncomeFromAnySource] == 1
              if income.values_at(*income_sources).none?
                enrollment[:reason] = 'Indicated sources, yet no sources exist'
                poor_quality[id] = enrollment
              end
            end
          end
        end
      end
      poor_quality
    end

    # there is much commentary on this method in q4
    def add_income_at_entry_answers
      client_ids = (@adults.keys + other_heads.keys).uniq
      
      # This potentially contains more income records than we need
      # since we only care about the most recent enrollment 
      incomes = incomes_by_enrollment(client_ids: client_ids, stage: :entry)

      poor_quality = aggregate_incomes client_ids, incomes

      @clients_with_issues += poor_quality.keys
      
      @answers[:q6c_b3][:value] = poor_quality.size
      @support[:q6c_b3][:support] = add_support(
        headers: ['Client ID', 'Project', 'Entry', 'Exit', 'Reason'],
        data: poor_quality.map do |_, enrollment|
          enrollment.values_at :client_id, :project_name, :first_date_in_program, :last_date_in_program, :reason
        end
      )
      @answers[:q6c_c3][:value] = ((poor_quality.size.to_f / (@adults.count + other_heads.count)) * 100).round(2)
    end

    # again, see comments for q4 method
    def add_income_at_exit_answers
      client_ids = adult_leavers_and_heads_of_household_leavers.keys
      
      # This potentially contains more income records than we need
      # since we only care about the most recent enrollment 
      incomes = incomes_by_enrollment(client_ids: client_ids, stage: :exit)

      poor_quality = aggregate_incomes client_ids, incomes

      @clients_with_issues += poor_quality.keys
      
      @answers[:q6c_b5][:value] = poor_quality.size
      @support[:q6c_b5][:support] = add_support(
        headers: ['Client ID', 'Project', 'Entry', 'Exit', 'Reason'],
        data: poor_quality.map do |_, enrollment|
          enrollment.values_at :client_id, :project_name, :first_date_in_program, :last_date_in_program, :reason
        end
      )
      @answers[:q6c_c5][:value] = ((poor_quality.size.to_f / adult_leavers_and_heads_of_household_leavers.count) * 100).round(2)
    end

    def add_income_annual_update_answers
      clients_with_enrollments = adult_stayers_and_heads_of_household_stayers.each do |id, enrollment|
        enrollment[:stay_length] = stay_length(
          client_id:           id,
          entry_date:          enrollment[:first_date_in_program],
          enrollment_group_id: enrollment[:enrollment_group_id]
        )
      end.to_h.select do |_,enrollment|
        enrollment[:stay_length] >= 365
      end

      incomes = incomes_by_enrollment( client_ids: clients_with_enrollments.keys, stage: :annual )

      poor_quality = Hash.new
      clients_with_enrollments.each do |id, enrollment|
        anniversary_incomes = incomes[
          enrollment.values_at :client_id, :enrollment_group_id, :project_id, :data_source_id
        ]
        if anniversary_incomes.blank?
          enrollment[:reason] = 'Missing income assessment'
          poor_quality[id] = enrollment
        else
          anniversary = anniversary_date(enrollment[:first_date_in_program])
          anniversary_incomes.select! do |income|
            ( income[:InformationDate] - anniversary ).abs > 30
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
                if income.values_at(*income_sources).any?
                  enrollment[:reason] = 'Indicated no sources, yet sources exist'
                  poor_quality[id] = enrollment
                end
              elsif income[:IncomeFromAnySource] == 1
                if income.values_at(*income_sources).none?
                  enrollment[:reason] = 'Indicated sources, yet no sources exist'
                  poor_quality[id] = enrollment
                end
              end
            end
          end
        end
      end
      @clients_with_issues += poor_quality.keys

      @answers[:q6c_b4][:value] = poor_quality.size
      @support[:q6c_b4][:support] = add_support(
        headers: ['Client ID', 'Project', 'Entry', 'Exit', 'Reason'],
        data: poor_quality.map do |_, enrollment|
          enrollment.values_at :client_id, :project_name, :first_date_in_program, :last_date_in_program, :reason
        end
      )
      @answers[:q6c_c4][:value] = ((poor_quality.size.to_f / clients_with_enrollments.count) * 100).round(2)
    end

    def setup_questions
      {
        q6c_a1: {
          title:  nil,
          value: 'Data Element',
        },
        q6c_b1: {
          title:  nil,
          value: 'Error Count',
        },
        q6c_c1: {
          title:  nil,
          value: '% of Error Rate',
        },
        q6c_a2: {
          title:  nil,
          value: 'Destination (3.12)',
        },
        q6c_a3: {
          title:  nil,
          value: 'Income and Sources (4.2) at Start',
        },
        q6c_a4: {
          title:  nil,
          value: 'Income and Sources (4.2) at Annual Assessment',
        },
        q6c_a5: {
          title:  nil,
          value: 'Income and Sources (4.2) at Exit',
        },
        q6c_b2: {
          title:  'Destination (3.12) - Error Count',
          value: 0,
        },
        q6c_c2: {
          title:  'Destination (3.12) - % of Error Rate',
          value: 0,
        },
        q6c_b3: {
          title:  'Income and Sources (4.2) at Start - Error Count',
          value: 0,
        },
        q6c_c3: {
          title:  'Income and Sources (4.2) at Start - % of Error Rate',
          value: 0,
        },
        q6c_b4: {
          title:  'Income and Sources (4.2) at Annual Assessment - Error Rate',
          value: 0,
        },
        q6c_c4: {
          title:  'Income and Sources (4.2) at Annual Assessment - % of Error Rate',
          value: 0,
        },
        q6c_b5: {
          title:  'Income and Sources (4.2) at Exit - Error Rate',
          value: 0,
        },
        q6c_c5: {
          title:  'Income and Sources (4.2) at Exit - % of Error Rate',
          value: 0,
        },
      }
    end

  end
end