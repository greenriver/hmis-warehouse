###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ReportGenerators::SystemPerformance::Fy2018
  class MeasureFive < Base
    LOOKBACK_STOP_DATE = '2012-10-01'

    # PH = [3,9,10,13]
    PH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:ph).flatten(1)
    # TH = [2]
    TH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:th).flatten(1)
    # ES = [1]
    ES = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:es).flatten(1)
    # SH = [8]
    SH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:sh).flatten(1)


    def run!
      # Disable logging so we don't fill the disk
      ActiveRecord::Base.logger.silence do
        calculate()
        Rails.logger.info "Done"
      end # End silence ActiveRecord Log
    end

    private

    def calculate
      if start_report(Reports::SystemPerformance::Fy2018::MeasureFive.first)
        set_report_start_and_end()
        Rails.logger.info "Starting report #{@report.report.name}"
        # Overview: Determine the number of clients in the system in specific programs during the
        # report period.  Of those, were any active in the two years prior?
        @answers = setup_questions()
        @support = @answers.deep_dup

        # Relevant Project Types/Program Types
        # 1: Emergency Shelter (ES)
        # 2: Transitional Housing (TH)
        # 3: Permanent Supportive Housing (disability required for entry) (PH)
        # 4: Street Outreach (SO)
        # 6: Services Only
        # 7: Other
        # 8: Safe Haven (SH)
        # 9: Permanent Housing (Housing Only) (PH)
        # 10: Permanent Housing (Housing with Services - no disability required for entry) (PH)
        # 11: Day Shelter
        # 12: Homeless Prevention
        # 13: Rapid Re-Housing (PH)
        # 14: Coordinated Entry
        add_es_sh_th_answers()
        add_es_sh_th_ph_answers()
        Rails.logger.info @answers.inspect
        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    def add_es_sh_th_answers
      # 5.1
      # Select clients entering any of the applicable project types in the report date range.
      relevent_project_types = ES + SH + TH
      set_client_universe(relevent_project_types)
      @answers[:five1_c2][:value] = @clients.size
      @support[:five1_c2][:support] = {
        headers:['Client ID'],
        counts: @clients.map{|id, _| [id]}
      }
      # save our progress
      @report.update(percent_complete: 1)
      # Determine the client's first start date within the date range
      previous_clients = find_first_entries(relevent_project_types)
      @answers[:five1_c3][:value] = previous_clients.size
      @support[:five1_c3][:support] = {
        headers: ['Client ID', 'Current Enrollment Start', 'Earlier Enrollment Start'],
        counts: previous_clients.map do |id, _|
          [
            id,
            @clients[id][:start_date],
            @clients[id][:earlier_entry],
          ]
        end
      }
      @answers[:five1_c4][:value] = @answers[:five1_c2][:value] - @answers[:five1_c3][:value]
      # save our progress
      update_report_progress(percent: 50)
    end

    def add_es_sh_th_ph_answers
      # 5.2
      # Select clients entering any of the applicable project types in the report date range.
      relevent_project_types = ES + SH + TH + PH
      set_client_universe(relevent_project_types)
      # save our progress
      @report.update(percent_complete: 51)
      @answers[:five2_c2][:value] = @clients.size
      @support[:five2_c2][:support] = {
        headers:['Client ID'],
        counts: @clients.map{|id, _| [id]}
      }
      # Determine the client's first start date within the date range
      previous_clients = find_first_entries(relevent_project_types)
      @answers[:five2_c3][:value] = previous_clients.size
      @support[:five2_c3][:support] = {
        headers: ['Client ID', 'Current Enrollment Start', 'Earlier Enrollment Start'],
        counts: previous_clients.map do |id, _|
          [
            id,
            @clients[id][:start_date],
            @clients[id][:earlier_entry],
          ]
        end
      }
      @answers[:five2_c4][:value] = @answers[:five2_c2][:value] - @answers[:five2_c3][:value]
       # save our progress
      update_report_progress(percent: 90)
    end

    def set_client_universe relevent_project_types
      @clients = {}
      client_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
        started_between(start_date: @report_start, end_date: @report_end + 1.day).
        hud_project_type(relevent_project_types)

      client_scope = add_filters(scope: client_scope)

      client_scope.
        select(:client_id).distinct.
        pluck(:client_id).each do |id|
          @clients[id] = {id: id}
        end
    end

    def find_first_entries relevent_project_types
      previous_clients = Set.new
      @clients.each do |id, client|
        sh_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
          where(client_id: id).
          hud_project_type(relevent_project_types).
          started_between(start_date: @report_start, end_date: @report_end + 1.day)

        sh_scope = add_filters(scope: sh_scope)

        @clients[id][:start_date] = sh_scope.
          order(first_date_in_program: :asc).
          minimum(:first_date_in_program)
      end
      # See if the client was active wthin the two years prior to their start date
      # Specifically, see if we started a program before the first start within the report range
      # and that program is either ongoing or ended within the two years before (not prior)
      # This should encompass all project types (same as 5.2)
      all_project_types = ES + SH + TH + PH
      @clients.each do |id, client|
        look_back_until =  LOOKBACK_STOP_DATE.to_date >= (client[:start_date].to_date - 730.days) ? LOOKBACK_STOP_DATE : (client[:start_date].to_date - 730.days).strftime('%Y-%m-%d')
        earlier_date = GrdaWarehouse::ServiceHistoryEnrollment.entry.
          where(client_id: id).
          hud_project_type(all_project_types).
          where(she_t[:first_date_in_program].lt(client[:start_date]).
            and(she_t[:last_date_in_program].eq(nil).
              or(she_t[:last_date_in_program].gteq(look_back_until))
            )
          ).
          order(first_date_in_program: :asc).
          minimum(:first_date_in_program)

        if earlier_date.present?
          @clients[id][:earlier_entry] = earlier_date
          # clients[id][:early_start_date] = @answers.first['first_date_in_program']
          previous_clients << id
        end
      end
      return previous_clients
    end

    def setup_questions
      {
        five1_a2: {
          title: nil,
          value: 'Universe: Person with entries in ES, SH or TH during the reporting period',
        },
        five1_a3: {
          title: nil,
          value: 'Of persons above, count those who were in ES, SH, TH or any PH within 24 months prior their entry during the reporting year',
        },
        five1_a4: {
          title: nil,
          value: 'Of persons above, count those who did not have entries in ES, SH, TH or PH in the previous 24 months (i.e. Number of persons experiencing homelessness for the first time.)',
        },
        five1_b1: {
          title: nil,
          value: 'Previous FY',
        },
        five1_b2: {
          title: 'Universe: Person with entries in ES, SH or TH during the reporting period (previous FY)',
          value: nil,
        },
        five1_b3: {
          title: 'Of persons above, count those who were in ES, SH, TH or any PH within 24 months prior their entry during the reporting year (previous FY)',
          value: nil,
        },
        five1_b4: {
          title: 'Of persons above, count those who did not have entries in ES, SH, TH or PH in the previous 24 months (i.e. Number of persons experiencing homelessness for the first time.) (previous FY)',
          value: nil,
        },
        five1_c1: {
          title: nil,
          value: 'Current FY',
        },
        five1_c2: {
          title: 'Universe: Person with entries in ES, SH or TH during the reporting period (current FY)',
          value: 0,
        },
        five1_c3: {
          title: 'Of persons above, count those who were in ES, SH, TH or any PH within 24 months prior their entry during the reporting year (current FY)',
          value: 0,
        },
        five1_c4: {
          title: 'Of persons above, count those who did not have entries in ES, SH, TH or PH in the previous 24 months (i.e. Number of persons experiencing homelessness for the first time.) (current FY)',
          value: 0,
        },
        five1_d1: {
          title: nil,
          value: 'Difference',
        },
        five1_d2: {
          title: 'Universe: Person with entries in ES, SH or TH during the reporting period (difference)',
          value: nil,
        },
        five1_d3: {
          title: 'Of persons above, count those who were in ES, SH, TH or any PH within 24 months prior their entry during the reporting year (difference)',
          value: nil,
        },
        five1_d4: {
          title: 'Of persons above, count those who did not have entries in ES, SH, TH or PH in the previous 24 months (i.e. Number of persons experiencing homelessness for the first time.) (difference)',
          value: nil,
        },
        five2_a2: {
          title: nil,
          value: 'Universe: Person with entries in ES, SH, TH or PH during the reporting period',
        },
        five2_a3: {
          title: nil,
          value: 'Of persons above, count those who were in ES, SH, TH or any PH within 24 months prior their entry during the reporting year',
        },
        five2_a4: {
          title: nil,
          value: 'Of persons above, count those who did not have entries in ES, SH, TH or PH in the previous 24 months (i.e. Number of persons experiencing homelessness for the first time.)',
        },
        five2_b1: {
          title: nil,
          value: 'Previous FY',
        },
        five2_b2: {
          title: 'Universe: Person with entries in ES, SH, TH or PH during the reporting period (previous FY)',
          value: nil,
        },
        five2_b3: {
          title: 'Of persons above, count those who were in ES, SH, TH or any PH within 24 months prior their entry during the reporting year (previous FY)',
          value: nil,
        },
        five2_b4: {
          title: 'Of persons above, count those who did not have entries in ES, SH, TH or PH in the previous 24 months (i.e. Number of persons experiencing homelessness for the first time.) (previous FY)',
          value: nil,
        },
        five2_c1: {
          title: nil,
          value: 'Current FY',
        },
        five2_c2: {
          title: 'Universe: Person with entries in ES, SH, TH or PH during the reporting period (current FY)',
          value: 0,
        },
        five2_c3: {
          title: 'Of persons above, count those who were in ES, SH, TH or any PH within 24 months prior their entry during the reporting year (current FY)',
          value: 0,
        },
        five2_c4: {
          title: 'Of persons above, count those who did not have entries in ES, SH, TH or PH in the previous 24 months (i.e. Number of persons experiencing homelessness for the first time.) (current FY)',
          value: 0,
        },
        five2_d1: {
          title: nil,
          value: 'Difference',
        },
        five2_d2: {
          title: 'Universe: Person with entries in ES, SH, TH or PH during the reporting period (difference)',
          value: nil,
        },
        five2_d3: {
          title: 'Of persons above, count those who were in ES, SH, TH or any PH within 24 months prior their entry during the reporting year (difference)',
          value: nil,
        },
        five2_d4: {
          title: 'Of persons above, count those who did not have entries in ES, SH, TH or PH in the previous 24 months (i.e. Number of persons experiencing homelessness for the first time.) (difference)',
          value: nil,
        },
      }
    end
  end
end
