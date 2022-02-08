###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ReportGenerators::SystemPerformance::Fy2019
  class MeasureFour < Base
    LOOKBACK_STOP_DATE = '2012-10-01'

    # PH = [3,9,10,13]
    PH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:ph).flatten(1)
    # TH = [2]
    TH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:th).flatten(1)
    # ES = [1]
    ES = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:es).flatten(1)
    # SH = [8]
    SH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:sh).flatten(1)

    FUNDING_SOURCES= [2, 3, 4, 5, 43, 44]

    def run!
      # Disable logging so we don't fill the disk
      ActiveRecord::Base.logger.silence do
        calculate()
        Rails.logger.info "Done"
      end # End silence ActiveRecord Log
    end


    def calculate
      if start_report(Reports::SystemPerformance::Fy2019::MeasureFour.first)
        set_report_start_and_end()
        Rails.logger.info "Starting report #{@report.report.name}"
        @answers = setup_questions()
        @support = @answers.deep_dup
        add_stayer_answers()
        update_report_progress(percent: 50)
        add_leaver_answers()
        update_report_progress(percent: 90)

        Rails.logger.info @answers.inspect
        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    def add_stayer_answers
      # To get the appropriate Federal Partner Funding Sources (2.6) we need to look at the agency info table provided by Jennifer Flynn from DND
      # Specifically we need 2,3,4,5 which correlate to:
      # FederalPartnerProgram = 'HUD CoC' and Component in ('PSH', 'RRH', 'SSO', 'TH')

      # sql = "
      #   select programid, databaseid
      #   from hud_performance_agency_program_info
      #   where CoCFunded = 1
      #     and Component in ('PSH', 'RRH', 'SSO', 'TH')
      #     and GrantStartDate <= '#{@report_end}'
      #     and (GrantEndDate is null or GrantEndDate >= '#{@report_start}')
      #     and ProgramTypeCode in (#{(PH + SH + TH).join(', ')})
      # "
      # Find anyone 18 years or older in a relevant project,
      # get their latest project entry date within the report range for which the length of stay is >= 365 days.
      universe_of_stayers = calculate_stayers
      update_report_progress(percent: 10)
      # Per Jennifer Flynn, ignore 60 day window around program start anniversary,
      # that was not the instructions given to programs about when to collect assessments
      universe_of_stayers = add_stayer_income(universe_of_stayers)
      update_report_progress(percent: 40)
      @answers[:four1_c2][:value] = universe_of_stayers.size
      @answers[:four2_c2][:value] = universe_of_stayers.size
      @answers[:four3_c2][:value] = universe_of_stayers.size

      client_personal_ids = personal_ids(universe_of_stayers.map{ |client| client[:client_id] })

      @support[:four1_c2][:support] = {
        headers: ['Client ID', 'Personal IDs', 'Project Name', 'Entry Date', 'Exit Date'],
        counts: universe_of_stayers.map do |client|
          [
            client[:client_id],
            client_personal_ids[client[:client_id]].join(', '),
            client[:project_name],
            client[:first_date_in_program],
            client[:last_date_in_program],
          ]
        end
      }
      universe_of_stayers.each do |client|
        next unless client[:latest_earned_income].present?

        if client[:latest_earned_income] - client[:earliest_earned_income] > 0
          @answers[:four1_c3][:value] += 1
          @support[:four1_c3][:support] ||= {
            headers: ['Client ID', 'Personal IDs', 'Latest Earned Income', 'Earliest Earned Income'],
            counts: []
          }
          @support[:four1_c3][:support][:counts] << [
            client[:client_id],
            client_personal_ids[client[:client_id]].join(', '),
            client[:latest_earned_income],
            client[:earliest_earned_income],
          ]
        end

        if client[:latest_non_earned_income] - client[:earliest_non_earned_income] > 0
          @answers[:four2_c3][:value] += 1
          @support[:four2_c3][:support] ||= {
            headers: ['Client ID', 'Personal IDs', 'Latest Non-Earned Income', 'Earliest Non-Earned Income'],
            counts: []
          }
          @support[:four2_c3][:support][:counts] << [
            client[:client_id],
            client_personal_ids[client[:client_id]].join(', '),
            client[:latest_non_earned_income],
            client[:earliest_non_earned_income],
          ]
        end

        if (client[:latest_earned_income] + client[:latest_non_earned_income]) - (client[:earliest_earned_income] + client[:earliest_non_earned_income]) > 0
          @answers[:four3_c3][:value] += 1
          @support[:four3_c3][:support] ||= {
            headers: ['Client ID',  'Personal IDs', 'Latest Total Income', 'Earliest Total Income'],
            counts: []
          }
          @support[:four3_c3][:support][:counts] << [
            client[:client_id],
            client_personal_ids[client[:client_id]].join(', '),
            client[:latest_earned_income] + client[:latest_non_earned_income],
            client[:earliest_earned_income] + client[:earliest_non_earned_income],
          ]
        end
      end
      @answers[:four1_c4][:value] = (@answers[:four1_c3][:value].to_f / @answers[:four1_c2][:value] * 100).round(2) rescue 0
      @answers[:four2_c4][:value] = (@answers[:four2_c3][:value].to_f / @answers[:four2_c2][:value] * 100).round(2) rescue 0
      @answers[:four3_c4][:value] = (@answers[:four3_c3][:value].to_f / @answers[:four3_c2][:value] * 100).round(2) rescue 0
    end

    def add_leaver_answers
      universe_of_leavers = calculate_leavers
      update_report_progress(percent: 50)
      universe_of_leavers = add_leaver_income(universe_of_leavers)
      update_report_progress(percent: 90)
      @answers[:four4_c2][:value] = universe_of_leavers.size
      @answers[:four5_c2][:value] = universe_of_leavers.size
      @answers[:four6_c2][:value] = universe_of_leavers.size

      client_personal_ids = personal_ids(universe_of_leavers.map{ |client| client[:client_id] })

      @support[:four4_c2][:support] = {
        headers: ['Client ID', 'Personal IDs', 'Project Name', 'Entry Date', 'Exit Date'],
        counts: universe_of_leavers.map do |client|
          [
            client[:client_id],
            client_personal_ids[client[:client_id]].join(', '),
            client[:project_name],
            client[:first_date_in_program],
            client[:last_date_in_program],
          ]
        end
      }
      universe_of_leavers.each do |client|
        next unless client[:latest_earned_income].present?

        if client[:latest_earned_income] - client[:earliest_earned_income] > 0
          @answers[:four4_c3][:value] += 1
          @support[:four4_c3][:support] ||= {
            headers: ['Client ID', 'Personal IDs', 'Latest Earned Income', 'Earliest Earned Income'],
            counts: []
          }
          @support[:four4_c3][:support][:counts] << [
            client[:client_id],
            client_personal_ids[client[:client_id]].join(', '),
            client[:latest_earned_income],
            client[:earliest_earned_income],
          ]
        end

        if client[:latest_non_earned_income] - client[:earliest_non_earned_income] > 0
          @answers[:four5_c3][:value] += 1
          @support[:four5_c3][:support] ||= {
            headers: ['Client ID', 'Personal IDs', 'Latest Non-Earned Income', 'Earliest Non-Earned Income'],
            counts: []
          }
          @support[:four5_c3][:support][:counts] << [
            client[:client_id],
            client_personal_ids[client[:client_id]].join(', '),
            client[:latest_non_earned_income],
            client[:earliest_non_earned_income],
          ]
        end

        if (client[:latest_earned_income] + client[:latest_non_earned_income]) - (client[:earliest_earned_income] + client[:earliest_non_earned_income]) > 0
          @answers[:four6_c3][:value] += 1
          @support[:four6_c3][:support] ||= {
            headers: ['Client ID', 'Personal IDs', 'Latest Total Income', 'Earliest Total Income'],
            counts: []
          }
          @support[:four6_c3][:support][:counts] << [
            client[:client_id],
            client_personal_ids[client[:client_id]].join(', '),
            client[:latest_earned_income] + client[:latest_non_earned_income],
            client[:earliest_earned_income] + client[:earliest_non_earned_income],
          ]
        end
      end
      @answers[:four4_c4][:value] = (@answers[:four4_c3][:value].to_f / @answers[:four4_c2][:value] * 100).round(2) rescue 0
      @answers[:four5_c4][:value] = (@answers[:four5_c3][:value].to_f / @answers[:four5_c2][:value] * 100).round(2) rescue 0
      @answers[:four6_c4][:value] = (@answers[:four6_c3][:value].to_f / @answers[:four6_c2][:value] * 100).round(2) rescue 0
    end

    def calculate_stayers
      # 1. A “system stayer” is a client active in any one or more of the relevant projects as of the [report end date]. CoC Performance Measures Programming Specifications
      # Page 24 of 41
      # 2. The client must have at least 365 days in latest stay to be included in this measure, using either bed-night or entry exit (you have to count the days)
      # 3. The client must be an adult to be included in this measure.

      columns = {
        she_t[:client_id] => :client_id,
        she_t[:first_date_in_program] => :first_date_in_program,
        she_t[:last_date_in_program] => :last_date_in_program,
        she_t[:project_id] => :project_id,
        she_t[:age] => :age,
        c_t[:DOB] => :DOB,
        she_t[:enrollment_group_id] => :enrollment_group_id,
        c_t[:PersonalID] => :PersonalID,
        she_t[:data_source_id] => :data_source_id,
        she_t[:project_tracking_method] => :project_tracking_method,
        she_t[:project_name] => :project_name,
        she_t[:id] => :enrollment_id,
      }

      stayers_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
        ongoing(on_date: @report_start). # need at least 365 days and open on end date
        ongoing(on_date: @report_end).
        hud_project_type(PH + SH + TH).
        joins(:client, project: :funders).
        where(Funder: {Funder: FUNDING_SOURCES}).
        grant_funded_between(start_date: @report_start, end_date: @report_end + 1.day)
        if @report.options['coc_code'].present?
          stayers_scope = stayers_scope.coc_funded_in(coc_code: @report.options['coc_code'])
        end

      stayers_scope = add_filters(scope: stayers_scope)

      stayers = stayers_scope.
        order(client_id: :asc, first_date_in_program: :asc).
        pluck(*columns.keys).map do |row|
          Hash[columns.values.zip(row)]
        end.map do |enrollment|
          enrollment[:age] = age_for_report(dob: enrollment[:DOB], entry_date: enrollment[:first_date_in_program], age: enrollment[:age])
          enrollment
        end.group_by do |row|
          row[:client_id]
        end.map do |_,enrollments|
          # Any enrollment with project_tracking_method != 3 will have 365 days
          # based on being open for the full year
          long_enrollments = enrollments.select{|m| m[:project_tracking_method] != 3}

          bed_night_enrollments = enrollments.select{|m| m[:project_tracking_method] == 3}
          long_enrollments += bed_night_enrollments.select do |enrollment|
            night_count = GrdaWarehouse::ServiceHistoryService.service.
              where(
                client_id: enrollment[:client_id],
                service_history_enrollment_id: enrollment[:enrollment_id]
              ).select(:date).
              distinct.
              count
            night_count > 365
          end

          # Keep only the last enrollment for the client
          # Use the client age at the report start or last enrollment, whichever date is later
          final_enrollment = long_enrollments.sort_by{|m| m[:first_date_in_program]}.last
          if final_enrollment[:DOB].present? && (final_enrollment[:first_date_in_program] < @report_start)
            final_enrollment[:age] = GrdaWarehouse::Hud::Client.age(date: @report_start, dob: final_enrollment[:DOB])
          end
          final_enrollment
        end.select do |row|
          # We only look at adults
          row[:age].blank? || row[:age] >= 18
        end
    end

    def calculate_leavers
      # 1. A “system leaver” is any client who has exited from one or more of the relevant projects between [report start date] and [report end date] and who
      # is not active in any of the relevant projects as of the [report end date].
      # 2. The client must be an adult to be included.

      columns = {
        she_t[:client_id] => :client_id,
        she_t[:first_date_in_program] => :first_date_in_program,
        she_t[:last_date_in_program] => :last_date_in_program,
        she_t[:project_id] => :project_id,
        she_t[:age] => :age,
        c_t[:DOB] => :DOB,
        she_t[:enrollment_group_id] => :enrollment_group_id,
        c_t[:PersonalID] => :PersonalID,
        she_t[:data_source_id] => :data_source_id,
        she_t[:project_tracking_method] => :project_tracking_method,
        she_t[:project_name] => :project_name,
      }

      client_id_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
        ongoing(on_date: @report_end).
        hud_project_type(PH + SH + TH).
        joins(project: :funders).
        where(Funder: {Funder: FUNDING_SOURCES}).
        grant_funded_between(start_date: @report_start,
          end_date: @report_end + 1.day)

      client_id_scope = add_filters(scope: client_id_scope)

      leavers_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
        ended_between(start_date: @report_start,
          end_date: @report_end + 1.days).
        hud_project_type(PH + SH + TH).
        where.not(
          client_id: client_id_scope.
            select(:client_id).
            distinct
        ).
        joins(:client, project: :funders).
        where(Funder: {Funder: FUNDING_SOURCES}).
        grant_funded_between(start_date: @report_start,
          end_date: @report_end + 1.day)

      if @report.options['coc_code'].present?
          leavers_scope = leavers_scope.coc_funded_in(coc_code: @report.options['coc_code'])
        end

      leavers_scope = add_filters(scope: leavers_scope)

      leavers = leavers_scope.
        order(client_id: :asc, first_date_in_program: :asc).
        pluck(*columns.keys).map do |row|
          Hash[columns.values.zip(row)]
        end.group_by do |row|
          row[:client_id]
        end.map do |k,v|
          # Keep only the last enrollment for the client
          # Use the client age at the report start or last enrollment, whichever date is later
          final_enrollment = v.last
          final_enrollment[:age] = age_for_report(dob: final_enrollment[:DOB], entry_date: final_enrollment[:first_date_in_program], age: final_enrollment[:age])
          final_enrollment
        end.select do |row|
          # We only look at adults
          row[:age].blank? || row[:age] >= 18
        end
    end

    def add_stayer_income universe_of_stayers
      # add columns to each row for the following:
      # latest_earned_income -- SourceCode = 1 & IncomeBenefitType = 1
      # latest_non_earned_income -- IncomeBenefitType = 2 || IncomeBenefitType = 1 && SourceCode <> 1
      # earliest_earned_income -- SourceCode = 1 & IncomeBenefitType = 1
      # earliest_non_earned_income -- IncomeBenefitType = 2 || IncomeBenefitType = 1 && SourceCode <> 1

      universe_of_stayers.each_with_index do |row, index|
        amount_columns = [:EarnedAmount, :UnemploymentAmount, :SSIAmount, :SSDIAmount, :VADisabilityServiceAmount, :VADisabilityNonServiceAmount, :PrivateDisabilityAmount, :WorkersCompAmount, :TANFAmount, :GAAmount, :SocSecRetirementAmount, :PensionAmount, :ChildSupportAmount, :AlimonyAmount, :OtherIncomeAmount]
        columns = [:TotalMonthlyIncome, :IncomeFromAnySource, :InformationDate, :DataCollectionStage] + amount_columns

        income_table = GrdaWarehouse::Hud::IncomeBenefit.arel_table

        assessments = GrdaWarehouse::Hud::IncomeBenefit.
          joins(enrollment: :service_history_enrollment).
          where(she_t[:client_id].eq(row[:client_id])).
          where(EnrollmentID: row[:enrollment_group_id]).
          where(data_source_id: row[:data_source_id]).
          where(income_table[:InformationDate].lteq(@report_end)).
          where(DataCollectionStage: [5, 1]).
          order(InformationDate: :asc).
          pluck(*columns).map do |row|
            Hash[columns.zip(row)]
          end.group_by{|m| m[:DataCollectionStage]}

        income_map = {} # make a useful group of income data {1 => date => [rows], 5 => date => [rows]}
        assessments.each do |stage, assessments|
          income_map[stage] = assessments.group_by{|m| m[:InformationDate]}
        end
        # Grab the last day from the 5 (annual assessment) group
        if income_map[5].present?
          latest_group = income_map[5].values.last.first
        end
        # If we have more than one 5, use the first as the earliest, otherwise if we have a 1 group use that, if not, we won't calculate
        if income_map[5].present? && income_map[5].size > 1
          earliest_group = income_map[5].values.first.first
        elsif income_map[1].present?
          earliest_group = income_map[1].values.first.first
        end
        if latest_group.present?
          if latest_group[:IncomeFromAnySource] == 1
            universe_of_stayers[index][:latest_income] = latest_group[:TotalMonthlyIncome] || 0
            universe_of_stayers[index][:latest_earned_income] = latest_group[:EarnedAmount] || 0
            universe_of_stayers[index][:latest_non_earned_income] = universe_of_stayers[index][:latest_income] - universe_of_stayers[index][:latest_earned_income]
          end
        end
        if earliest_group.present?
          if earliest_group[:IncomeFromAnySource] == 1
            universe_of_stayers[index][:earliest_income] = earliest_group[:TotalMonthlyIncome] || 0
            universe_of_stayers[index][:earliest_earned_income] = earliest_group[:EarnedAmount] || 0
            universe_of_stayers[index][:earliest_non_earned_income] = universe_of_stayers[index][:earliest_income] - universe_of_stayers[index][:earliest_earned_income]
          else
            universe_of_stayers[index][:earliest_income] = 0
            universe_of_stayers[index][:earliest_earned_income] = 0
            universe_of_stayers[index][:earliest_non_earned_income] = 0
          end
        end
      end
      universe_of_stayers.select{|m| m[:earliest_income].present?}
    end

    # TODO DRY This up?
    def add_leaver_income universe_of_leavers
      # add columns to each row for the following:
      # latest_earned_income -- SourceCode = 1 & IncomeBenefitType = 1
      # latest_non_earned_income -- IncomeBenefitType = 2 || IncomeBenefitType = 1 && SourceCode <> 1
      # earliest_earned_income -- SourceCode = 1 & IncomeBenefitType = 1
      # earliest_non_earned_income -- IncomeBenefitType = 2 || IncomeBenefitType = 1 && SourceCode <> 1

      universe_of_leavers.each_with_index do |row, index|
        amount_columns = [:EarnedAmount, :UnemploymentAmount, :SSIAmount, :SSDIAmount, :VADisabilityServiceAmount, :VADisabilityNonServiceAmount, :PrivateDisabilityAmount, :WorkersCompAmount, :TANFAmount, :GAAmount, :SocSecRetirementAmount, :PensionAmount, :ChildSupportAmount, :AlimonyAmount, :OtherIncomeAmount]
        columns = [:TotalMonthlyIncome, :IncomeFromAnySource, :InformationDate, :DataCollectionStage] + amount_columns

        income_table = GrdaWarehouse::Hud::IncomeBenefit.arel_table

        assessments = GrdaWarehouse::Hud::IncomeBenefit.where(data_source_id: row[:data_source_id]).
          joins(enrollment: :service_history_enrollment).
          where(she_t[:client_id].eq(row[:client_id])).
          where(EnrollmentID: row[:enrollment_group_id]).
          where(data_source_id: row[:data_source_id]).
          where(income_table[:InformationDate].lteq(@report_end)).
          where(DataCollectionStage: [3, 1]).
          order(InformationDate: :asc).
          pluck(*columns).map do |row|
            Hash[columns.zip(row)]
          end.group_by{|m| m[:DataCollectionStage]}

        income_map = {} # make a useful group of income data {1 => date => [rows], 5 => date => [rows]}
        assessments.each do |stage, assessments|
          income_map[stage] = assessments.group_by{|m| m[:InformationDate]}
        end
        # Grab the last day from the 3 (exit assessment) group
        latest_group = income_map[3].values.last.first if income_map[3].present?
        earliest_group = income_map[1].values.first.first if income_map[1].present?

        if latest_group.present?
          if latest_group[:IncomeFromAnySource] == 1
            universe_of_leavers[index][:latest_income] = latest_group[:TotalMonthlyIncome] || 0
            universe_of_leavers[index][:latest_earned_income] = latest_group[:EarnedAmount] || 0
            universe_of_leavers[index][:latest_non_earned_income] = universe_of_leavers[index][:latest_income] - universe_of_leavers[index][:latest_earned_income]
          end
        end
        if earliest_group.present?
          if earliest_group[:IncomeFromAnySource] == 1
            universe_of_leavers[index][:earliest_income] = earliest_group[:TotalMonthlyIncome] || 0
            universe_of_leavers[index][:earliest_earned_income] = earliest_group[:EarnedAmount] || 0
            universe_of_leavers[index][:earliest_non_earned_income] = universe_of_leavers[index][:earliest_income] - universe_of_leavers[index][:earliest_earned_income]
          else
            universe_of_leavers[index][:earliest_income] = 0
            universe_of_leavers[index][:earliest_earned_income] = 0
            universe_of_leavers[index][:earliest_non_earned_income] = 0
          end
        end
      end
      universe_of_leavers.select{|m| m[:earliest_income].present?}
    end

    def setup_questions
      {
        four1_a2: {
          title:  nil,
          value: 'Universe: number of adults (system stayers)',
        },
        four1_a3: {
          title: nil,
          value: 'Number of adults with increased earned income',
        },
        four1_a4: {
          title: nil,
          value: 'Percentage of adults who increased earned income',
        },
        four1_b1: {
          title: nil,
          value: 'Previous FY',
        },
        four1_b2: {
          title: 'Universe: number of adults (system stayers - previous FY)',
          value: nil,
        },
        four1_b3: {
          title: 'Number of adults with increased earned income (previous FY)',
          value: nil,
        },
        four1_b4: {
          title: 'Percentage of adults who increased earned income (previous FY)',
          value: nil,
        },
        four1_c1: {
          title: nil,
          value: 'Current FY',
        },
        four1_c2: {
          title: 'Universe: number of adults (system stayers - current FY)',
          value: 0,
        },
        four1_c3: {
          title: 'Number of adults with increased earned income (current FY)',
          value: 0,
        },
        four1_c4: {
          title: 'Percentage of adults with increased earned income (current FY)',
          value: 0,
        },
        four1_d1: {
          title: nil,
          value: 'Difference',
        },
        four1_d2: {
          title: 'Universe: number of adults (system stayers - difference)',
          value: nil,
        },
        four1_d3: {
          title: 'Number of adults with increased earned income (difference)',
          value: nil,
        },
        four1_d4: {
          title: 'Percentage of adults who increased earned income (difference)',
          value: nil,
        },
        four2_a2: {
          title:  nil,
          value: 'Universe: number of adults (system stayers)',
        },
        four2_a3: {
          title: nil,
          value: 'Number of adults with increased non-employment cash income',
        },
        four2_a4: {
          title: nil,
          value: 'Percentage of adults who increased non-employment cash income',
        },
        four2_b1: {
          title: nil,
          value: 'Previous FY',
        },
        four2_b2: {
          title: 'Universe: number of adults (system stayers - previous FY)',
          value: nil,
        },
        four2_b3: {
          title: 'Number of adults with increased non-employment cash income (previous FY)',
          value: nil,
        },
        four2_b4: {
          title: 'Percentage of adults who increased non-employment cash income (previous FY)',
          value: nil,
        },
        four2_c1: {
          title: nil,
          value: 'Current FY',
        },
        four2_c2: {
          title: 'Universe: number of adults (system stayers - current FY)',
          value: 0,
        },
        four2_c3:{
          title: 'Number of adults with increased non-employment cash income (current FY)',
          value: 0,
        },
        four2_c4: {
          title: 'Percentage of adults who increased non-employment cash income (current FY)',
          value: 0,
        },
        four2_d1: {
          title: nil,
          value: 'Difference',
        },
        four2_d2: {
          title: 'Universe: number of adults (system stayers - difference)',
          value: nil,
        },
        four2_d3: {
          title: 'Number of adults with increased non-employment cash income (difference)',
          value: nil,
        },
        four2_d4: {
          title: 'Percentage of adults who increased non-employment cash income (difference)',
          value: nil,
        },
        four3_a2: {
          title:  nil,
          value: 'Universe: number of adults (system stayers)',
        },
        four3_a3: {
          title: nil,
          value: 'Number of adults with increased total income',
        },
        four3_a4: {
          title: nil,
          value: 'Percentage of adults who increased total income',
        },
        four3_b1: {
          title: nil,
          value: 'Previous FY',
        },
        four3_b2: {
          title: 'Universe: number of adults (system stayers - previous FY)',
          value: nil,
        },
        four3_b3: {
          title: 'Number of adults with increased total income (previous FY)',
          value: nil,
        },
        four3_b4: {
          title: 'Percentage of adults who increased total income (previous FY)',
          value: nil,
        },
        four3_c1: {
          title: nil,
          value: 'Current FY',
        },
        four3_c2: {
          title: 'Universe: number of adults (system stayers - current FY)',
          value: 0,
        },
        four3_c3: {
          title: 'Number of adults with increased total income (current FY)',
          value: 0,
        },
        four3_c4: {
          title: 'Percentage of adults who increased total income (current FY)',
          value: 0,
        },
        four3_d1: {
          title: nil,
          value: 'Difference',
        },
        four3_d2: {
          title: 'Universe: number of adults (system stayers - difference)',
          value: nil,
        },
        four3_d3: {
          title: 'Number of adults with increased total income (difference)',
          value: nil,
        },
        four3_d4: {
          title: 'Percentage of adults who increased total income (difference)',
          value: nil,
        },
        four4_a2: {
          title:  nil,
          value: 'Universe: number of adults (system leavers)',
        },
        four4_a3: {
          title: nil,
          value: 'Number of adults with increased earned income',
        },
        four4_a4: {
          title: nil,
          value: 'Percentage of adults who increased earned income',
        },
        four4_b1: {
          title: nil,
          value: 'Previous FY',
        },
        four4_b2: {
          title: 'Universe: number of adults (system leavers - previous FY)',
          value: nil,
        },
        four4_b3: {
          title: 'Number of adults with increased earned income (previous FY)',
          value: nil,
        },
        four4_b4: {
          title: 'Percentage of adults who increased earned income (previous FY)',
          value: nil,
        },
        four4_c1: {
          title: nil,
          value: 'Current FY',
        },
        four4_c2: {
          title: 'Universe: number of adults (system leavers - current FY)',
          value: 0,
        },
        four4_c3: {
          title: 'Number of adults with increased earned income (current FY)',
          value: 0,
        },
        four4_c4: {
          title: 'Percentage of adults with increased earned income (current FY)',
          value: 0,
        },
        four4_d1: {
          title: nil,
          value: 'Difference',
        },
        four4_d2: {
          title: 'Universe: number of adults (system leavers - difference)',
          value: nil,
        },
        four4_d3: {
          title: 'Number of adults with increased earned income (difference)',
          value: nil,
        },
        four4_d4: {
          title: 'Percentage of adults who increased earned income (difference)',
          value: nil,
        },
        four5_a2: {
          title:  nil,
          value: 'Universe: number of adults (system leavers)',
        },
        four5_a3: {
          title: nil,
          value: 'Number of adults with increased non-employment cash income',
        },
        four5_a4: {
          title: nil,
          value: 'Percentage of adults who increased non-employment cash income',
        },
        four5_b1: {
          title: nil,
          value: 'Previous FY',
        },
        four5_b2: {
          title: 'Universe: number of adults (system leavers - previous FY)',
          value: nil,
        },
        four5_b3: {
          title: 'Number of adults with increased non-employment cash income (previous FY)',
          value: nil,
        },
        four5_b4: {
          title: 'Percentage of adults who increased non-employment cash income (previous FY)',
          value: nil,
        },
        four5_c1: {
          title: nil,
          value: 'Current FY',
        },
        four5_c2: {
          title: 'Universe: number of adults (system leavers - current FY)',
          value: 0,
        },
        four5_c3:{
          title: 'Number of adults with increased non-employment cash income (current FY)',
          value: 0,
        },
        four5_c4: {
          title: 'Percentage of adults who increased non-employment cash income (current FY)',
          value: 0,
        },
        four5_d1: {
          title: nil,
          value: 'Difference',
        },
        four5_d2: {
          title: 'Universe: number of adults (system leavers - difference)',
          value: nil,
        },
        four5_d3: {
          title: 'Number of adults with increased non-employment cash income (difference)',
          value: nil,
        },
        four5_d4: {
          title: 'Percentage of adults who increased non-employment cash income (difference)',
          value: nil,
        },
        four6_a2: {
          title:  nil,
          value: 'Universe: number of adults (system leavers)',
        },
        four6_a3: {
          title: nil,
          value: 'Number of adults with increased total income',
        },
        four6_a4: {
          title: nil,
          value: 'Percentage of adults who increased total income',
        },
        four6_b1: {
          title: nil,
          value: 'Previous FY',
        },
        four6_b2: {
          title: 'Universe: number of adults (system leavers - previous FY)',
          value: nil,
        },
        four6_b3: {
          title: 'Number of adults with increased total income (previous FY)',
          value: nil,
        },
        four6_b4: {
          title: 'Percentage of adults who increased total income (previous FY)',
          value: nil,
        },
        four6_c1: {
          title: nil,
          value: 'Current FY',
        },
        four6_c2: {
          title: 'Universe: number of adults (system leavers - current FY)',
          value: 0,
        },
        four6_c3: {
          title: 'Number of adults with increased total income (current FY)',
          value: 0,
        },
        four6_c4: {
          title: 'Percentage of adults who increased total income (current FY)',
          value: 0,
        },
        four6_d1: {
          title: nil,
          value: 'Difference',
        },
        four6_d2: {
          title: 'Universe: number of adults (system leavers - difference)',
          value: nil,
        },
        four6_d3: {
          title: 'Number of adults with increased total income (difference)',
          value: nil,
        },
        four6_d4: {
          title: 'Percentage of adults who increased total income (difference)',
          value: nil,
        },
      }
    end
  end
end
