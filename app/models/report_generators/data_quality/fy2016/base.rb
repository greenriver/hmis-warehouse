module ReportGenerators::DataQuality::Fy2016
  class Base
    include ArelHelper

    def add_filters scope:
      if @report.options['project_id'].present?
        scope = scope.joins(:project).where(project: { id: @report.options['project_id'].to_i})
      end
      if @report.options['data_source_id'].present?
        scope = scope.where(data_source_id: @report.options['data_source_id'].to_i)
      end
      if @report.options['coc_code']
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

    # def replace_project_type_with_overlay(headers)
    #   headers.map do |v| 
    #     if v == :project_type
    #       act_as_project_overlay 
    #     else
    #       v 
    #     end
    #   end
    # end

    def all_client_scope
      client_scope = GrdaWarehouse::ServiceHistory.entry.
        open_between(start_date: @report.options['report_start'],
          end_date: @report.options['report_end']).
        joins(:client)

      add_filters(scope: client_scope)
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
      # @households ||= {}.tap do |h|

      #   columns = [:client_id, :age, :head_of_household_id, :household_id, :RelationshipToHoH]
      #   @all_clients.each do |id, enrollments|
      #     enrollment = enrollments.last
      #     h[id] = GrdaWarehouse::ServiceHistory.entry.
      #       where(household_id: enrollment[:household_id],
      #         first_date_in_program: enrollment[:first_date_in_program], project_id: enrollment[:project_id]).
      #       joins(:client, :enrollment).
      #       pluck(*columns).map do |row|
      #         Hash[columns.zip(row)]
      #       end
      #   end
      # end
      @households
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