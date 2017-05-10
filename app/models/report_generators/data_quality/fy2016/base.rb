module ReportGenerators::DataQuality::Fy2016
  class Base
    ADULT = 18
    include ArelHelper
    attr_reader :all_clients

    def add_filters scope:
      if @report.options['project_id'].delete_if(&:blank?).any?
        project_ids = @report.options['project_id'].delete_if(&:blank?).map(&:to_i)
        scope = scope.joins(:project).where(project: { id: project_ids})
      end
      if @report.options['data_source_id'].present?
        scope = scope.where(data_source_id: @report.options['data_source_id'].to_i)
      end
      if @report.options['coc_code'].present?
        scope = scope.coc_funded_in(coc_code: @report.options['coc_code'])
      end
      if @report.options['project_type'].delete_if(&:blank?).any?
        project_types = @report.options['project_type'].delete_if(&:blank?).map(&:to_i)
        scope = scope.hud_project_type(project_types)
      end

      return scope
    end

    def act_as_coc_overlay
      pt = GrdaWarehouse::Hud::ProjectCoC.arel_table
      nf( 'COALESCE', [ pt[:hud_coc_code], pt[:CoCCode] ] ).as('CoCCode').to_sql
    end

    def act_as_project_overlay
      pt = GrdaWarehouse::Hud::Project.arel_table
      st = GrdaWarehouse::ServiceHistory.arel_table
      nf( 'COALESCE', [ pt[:act_as_project_type], st[:project_type] ] ).as('project_type').to_sql
    end

    def all_client_scope
      client_scope = GrdaWarehouse::ServiceHistory.entry.
        open_between(start_date: @report.options['report_start'],
          end_date: @report.options['report_end']).
        joins(:client)

      add_filters(scope: client_scope)
    end

    def leavers
      @leavers ||= begin
        # 1. A "system leaver" is any client who has exited from one or more of the relevant projects between [report start date] and [report end date] and who
        # is not active in any of the relevant projects as of the [report end date].
        # 2. The client must be an adult to be included.
        columns = [
          :client_id, 
          :first_date_in_program, 
          :last_date_in_program, 
          :project_id, 
          :age, 
          :DOB, 
          :enrollment_group_id, 
          :data_source_id, 
          :project_tracking_method, 
          :project_name, 
          :RelationshipToHoH, 
          :household_id,
          :destination,
        ]

        client_id_scope = GrdaWarehouse::ServiceHistory.entry.
          ongoing(on_date: @report.options['report_end'])

        client_id_scope = add_filters(scope: client_id_scope)

        leavers_scope = GrdaWarehouse::ServiceHistory.entry.
          ended_between(start_date: @report.options['report_start'].to_date + 1.days, 
            end_date: @report.options['report_end'].to_date + 1.days).
          where.not(
            client_id: client_id_scope.
              select(:client_id).
              distinct
          ).
          joins(:client, :enrollment)
          
        leavers_scope = add_filters(scope: leavers_scope)

        leavers_scope.
          order(client_id: :asc, first_date_in_program: :asc).
          pluck(*columns).map do |row|
            Hash[columns.zip(row)]
          end.group_by do |row|
            row[:client_id]
          end.map do |id,enrollments| 
            # We only care about the last enrollment
            [id, enrollments.last]
          end.to_h
      end
    end

    def stayers
      stayers ||= begin
        # 1. A "system stayer" is a client active in any one or more of the relevant projects as of the [report end date]. CoC Performance Measures Programming Specifications
        # 2. The client must have at least 365 days in latest stay to be included in this measure, using either bed-night or entry exit (you have to count the days) 
        # 3. The client must be an adult to be included in this measure.
        columns = [
          :client_id, 
          :first_date_in_program, 
          :last_date_in_program, 
          :project_id, 
          :age, 
          :DOB, 
          :enrollment_group_id, 
          :data_source_id, 
          :project_tracking_method, 
          :project_name, 
          :RelationshipToHoH, 
          :household_id,
        ]

        stayers_scope = GrdaWarehouse::ServiceHistory.entry.
          ongoing(on_date: @report.options['report_end']).
          joins(:client, :enrollment)

        stayers_scope = add_filters(scope: stayers_scope)

        stayers_scope.
          order(client_id: :asc, first_date_in_program: :asc).
          pluck(*columns).map do |row|
            Hash[columns.zip(row)]
          end.group_by do |row|
            row[:client_id]
          end.map do |id,enrollments| 
            # We only care about the last enrollment
            [id, enrollments.last]
          end.to_h
      end
    end

    def adult_stayers
      @adult_stayers ||= stayers.select do |_, enrollment|
        adult?(enrollment[:age])
      end
    end

    def adult_stayers_and_heads_of_household_stayers
      @adult_stayers_and_heads_of_household_stayers ||= stayers.select do |_, enrollment|
        adult?(enrollment[:age]) || head_of_household?(enrollment[:RelationshipToHoH])
      end
    end

    def adult?(age)
      age >= ADULT if age.present?
    end

    def child?(age)
      age < ADULT if age.present?
    end

    def head_of_household?(relationship)
      relationship.to_i == 1
    end

    def child_in_household?(relationship)
      relationship.to_i == 2
    end

    def valid_household_relationship?(relationship)
      (1..5).include?(relationship.to_i)
    end

    def valid_coc_code?(code)
      /^[a-zA-Z]{2}-[0-9]{3}$/.match(code).present?
    end

    def start_report(report)
      # Find the first queued report
      @report = ReportResult.where(
        report: report,
        percent_complete: 0
      ).first
      return unless @report.present? 
      Rails.logger.info "Starting report #{@report.report.name}"
      @report.update(percent_complete: 0.01)
    end

    def finish_report
      @report.update(
        percent_complete: 100, 
        results: @answers,
        support: @support,
        completed_at: Time.now
      )
    end

    def add_support headers:, data:
      {
        headers: headers,
        counts: data,
      }
    end

    def update_report_progress percent:
      @report.update(
        percent_complete: percent,
        results: @answers,
        support: @support,
      )
    end
    def all_client_count 
      count ||= @all_clients.size
    end

    def setup_age_categories
      clients_with_ages = @all_clients.map do |id, enrollments|
        [id, enrollments.last[:age]]
      end.to_h
      @adults = clients_with_ages.select do |_, age|
        adult?(age)
      end
      @children = clients_with_ages.select do |_, age|
        child?(age)
      end
      @unknown = clients_with_ages.select do |_, age|
        age.blank?
      end
    end

    def anniversary_date(date)
      date = date.to_date
      end_date = @report.options['report_end'].to_date
      anniversary_date = Date.new(end_date.year, date.month, date.day)
      anniversary_date = if anniversary_date > end_date then anniversary_date - 1.year else anniversary_date end
    end


    # create
    # [{
    #   <client_id>: {
    #     key: [ds_id, hh_id...],
    #     household: [enrollments]
    #   } 
    # }]
    def households
      @households ||= @all_clients.map do |id, enrollments|
        enrollment = enrollments.last
        household = @all_clients.values.flatten(1).select do |en|
          enrollment[:data_source_id] == en[:data_source_id] &&
          enrollment[:project_id] == en[:project_id] &&
          enrollment[:household_id] == en[:household_id] &&
          enrollment[:first_date_in_program] == en[:first_date_in_program]
        end
        [
          id,
          {
            key: [
              household.first[:data_source_id], 
              household.first[:project_id], 
              household.first[:household_id], 
              household.first[:first_date_in_program],
            ],
            household: household
          }
        ]
      end.to_h
      @households
    end

    def adult_heads
      households.select do |id, household|
        household[:household].select do |member|
          adult?(member[:age]) && head_of_household?(member[:RelationshipToHoH])
        end.any?
      end
    end

    def other_heads
      households.select do |id, household|
        household[:household].select do |member|
          ! adult?(member[:age]) && head_of_household?(member[:RelationshipToHoH])
        end.any?
      end
    end

    def adult_leavers_and_heads_of_household_leavers
      @adult_head_leavers ||= leavers.select do |_, enrollment|
        adult?(enrollment[:age]) || head_of_household?(enrollment[:RelationshipToHoH])
      end
    end

    def adult_leavers
      @adult_leavers ||= @leavers.select do |_, enrollment|
        adult?(enrollment[:age])
      end
    end

    def stay_length(client_id:, entry_date:, exit_date:)
      GrdaWarehouse::ServiceHistory.service.
        where(
          client_id: client_id, 
          first_date_in_program: entry_date,
          enrollment_group_id: exit_date
        ).
        select(:date).
        distinct.
        count
    end

    def client_disabled?(enrollment:)
      return true if enrollment[:DisablingCondition] == 1
      # load disabling conditions for client, we've indicated we don't have any.
      # If we do, we have a problem
      disabilities = [5,6,7,8,9]
      yes_responses = [1,2,3]
      GrdaWarehouse::Hud::Client.joins(:source_disabilities).
        where(id: enrollment[:client_id]).
        where(
          Disabilities: {
            DisabilityType: disabilities, 
            DisabilityResponse: yes_responses}
        ).count > 0
    end

    def living_situation_is_homeless enrollment:
      # [living situation] (3.917.1) = 16, 1, 18 or 27
      [16,1,18,27].include?(enrollment[:ResidencePrior]) ||
      # [on the night before, did you stay in streets, ES or SH?] (3.917.2c) 
      enrollment[:PreviousStreetESSH] == 1 ||
      # [project type] (2.4) = 1 or 4 or 8
      [1,4,8].include?(enrollment[:project_type])
    end

    def homeless_for_one_year? enrollment:
      enrollment[:DateToStreetESSH].present? && 
      enrollment[:DateToStreetESSH].to_date <= (enrollment[:first_date_in_program] - 365.days)
    end

    def four_or_more_episodes_and_12_months_or_365_days? enrollment:
      homeless_for_one_year?(enrollment: enrollment) ||
      enrollment[:TimesHomelessPastThreeYears].present? && enrollment[:TimesHomelessPastThreeYears] >= 4 &&
       enrollment[:MonthsHomelessPastThreeYears].present? && enrollment[:MonthsHomelessPastThreeYears] >= 12
    end
  end
end