###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ReportGenerators::SystemPerformance::Fy2019
  class MeasureThree < Base
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
      end # End silence ActiveRecord Log
    end

    private

    def calculate
      if start_report(Reports::SystemPerformance::Fy2019::MeasureThree.first)
        set_report_start_and_end()
        Rails.logger.info "Starting report #{@report.report.name}"
        update_report_progress(percent: 0.01)
        # Overview: collect annual counts of homeless persons by sheltering type
        @answers = setup_questions()
        @support = @answers.deep_dup

        add_total_unsheltered_answers()

        update_report_progress(percent: 30)

        add_homeless_breakdowns()


        Rails.logger.info @answers.inspect
        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end

    end

    def add_total_unsheltered_answers
      # Get totals
      shelter_types = ES + SH + TH

      columns = [
        :client_id,
        :project_name,
        :first_date_in_program,
      ]
      client_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
        with_service_between(start_date: @report_start - 1.day, end_date: @report_end).
        hud_project_type(shelter_types)
      client_scope = add_filters(scope: client_scope)

      clients = client_scope.
        select(*columns).
        distinct.
        pluck(*columns).map do |row|
          Hash[columns.zip(row)]
        end.group_by{ |row| row[:client_id]}
      @answers[:three2_c2][:value] = clients.size

      client_personal_ids = personal_ids(clients.keys)

      @support[:three2_c2][:support] = add_support(
        headers: ['Client ID', 'Personal IDs', 'Project', 'Start Date'],
        data: clients.map do |id, enrollments|
          [
            id,
            client_personal_ids[id].join(', '),
            enrollments.map{|en| en[:project_name]}.join('; '),
            enrollments.map{|en| en[:first_date_in_program]}.join('; '),
          ]
        end
        )
      update_report_progress(percent: 20)
    end

    def add_homeless_breakdowns
        # sql = "
        #   select distinct client_id, project_type
        #   from hud_performance_client_housing_history
        #   where [date] >= '#{@report.options['report_start']}'
        #     and ([date] < '#{@report.options['report_end']}' or ([date] <= '#{@report.options['report_end']}' and record_type = 'bed_night'))
        # "
        columns = {
          client_id: :client_id,
          project_type: :computed_project_type,
          project_name: :project_name,
          first_date_in_program: :first_date_in_program,
        }
        client_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
          joins(:project).
          with_service_between(start_date: @report_start - 1.day, end_date: @report_end)

        client_scope = add_filters(scope: client_scope)

        clients = client_scope.
          select(*columns.values).distinct.
          pluck(*columns.values).map do |row|
            Hash[columns.keys.zip(row)]
          end.group_by do |row|
            [row[:client_id], row[:project_type]]
          end


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
        es = {}
        sh = {}
        th = {}
        # count each person no more than once per type
        clients.each do |(client_id, project_type), enrollments|
          case project_type
            when *ES
              es[client_id] = project_type
            when *SH
              sh[client_id] = project_type
            when *TH
              th[client_id] = project_type
          end
        end
        @answers[:three2_c3][:value] = es.size
        @answers[:three2_c4][:value] = sh.size
        @answers[:three2_c5][:value] = th.size

        client_personal_ids = personal_ids(client_scope.pluck(:client_id))

        @support[:three2_c3][:support] = add_support(
          headers: ['Client ID', 'Personal IDs', 'Project(s)', 'Start Date(s)'],
          data: es.map do |id,project_type|
            project_names = clients[[id,project_type]].map{|en| en[:project_name]}.join('; ')
            entry_dates = clients[[id,project_type]].map{|en| en[:first_date_in_program]}.join('; ')
            [
              id,
              client_personal_ids[id].join(', '),
              project_names,
              entry_dates,
            ]

          end
        )
        @support[:three2_c4][:support] = add_support(
          headers: ['Client ID', 'Personal IDs', 'Project(s)', 'Start Date(s)'],
          data: sh.map do |id,project_type|
            project_names = clients[[id,project_type]].map{|en| en[:project_name]}.join('; ')
            entry_dates = clients[[id,project_type]].map{|en| en[:first_date_in_program]}.join('; ')
            [
              id,
              client_personal_ids[id].join(', '),
              project_names,
              entry_dates,
            ]

          end
        )
        @support[:three2_c5][:support] = add_support(
          headers: ['Client ID', 'Personal IDs', 'Project(s)', 'Start Date(s)'],
          data: th.map do |id,project_type|
            project_names = clients[[id,project_type]].map{|en| en[:project_name]}.join('; ')
            entry_dates = clients[[id,project_type]].map{|en| en[:first_date_in_program]}.join('; ')
            [
              id,
              client_personal_ids[id].join(', '),
              project_names,
              entry_dates,
            ]

          end
        )
        update_report_progress(percent: 90)
      end

    def setup_questions
      {
        three1_a2: {
          title:  nil,
          value: 'Total PIT count of sheltered and unsheltered persons',
        },
        three1_a3: {
          title: nil,
          value: 'Emergency shelter total',
        },
        three1_a4: {
          title: nil,
          value: 'Safe haven total',
        },
        three1_a5: {
          title: nil,
          value: 'Transitional housing total',
        },
        three1_a6: {
          title: nil,
          value: 'Total sheltered count',
        },
        three1_a7: {
          title: nil,
          value: 'Unsheltered count',
        },
        three1_b1: {
          title: nil,
          value: 'Previous FY PIT Count',
        },
        three1_b2: {
          title: 'Total PIT count of sheltered and unsheltered persons (previous FY)',
          value: nil,
        },
        three1_b3: {
          title: 'Emergency shelter total (previous FY)',
          value: nil,
        },
        three1_b4: {
          title: 'Safe haven total (previous FY)',
          value: nil,
        },
        three1_b5: {
          title: 'Transitional housing total (previous FY)',
          value: nil,
        },
        three1_b6: {
          title: 'Total sheltered count (previous FY)',
          value: nil,
        },
        three1_b7: {
          title: 'Unsheltered count (previous FY)',
          value: nil,
        },
        three1_c1: {
          title: nil,
          value: 'Current FY PIT Count',
        },
        three1_c2: { # Total unduplicated ES + SH + TH
          title: 'Total PIT count of sheltered and unsheltered persons (current FY)',
          value: nil,
        },
        three1_c3: { # Total in ES
          title: 'Emergency shelter total (current FY)',
          value: nil,
        },
        three1_c4: { # Total in SH
          title: 'Safe haven total (current FY)',
          value: nil,
        },
        three1_c5: { # Total in TH
          title: 'Transitional housing total (current FY)',
          value: nil,
        },
        three1_c6: {
          title: 'Total sheltered count (current FY)',
          value: nil,
        },
        three1_c7: {
          title: 'Unsheltered count (current FY)',
          value: nil,
        },
        three1_d2: {
          title: 'Total PIT count of sheltered and unsheltered persons (difference)',
          value: nil,
        },
        three1_d1: {
          title: nil,
          value: 'Difference',
        },
        three1_d3: {
          title: 'Emergency shelter total (difference)',
          value: nil,
        },
        three1_d4: {
          title: 'Safe haven total (difference)',
          value: nil,
        },
        three1_d5: {
          title: 'Transitional housing total (difference)',
          value: nil,
        },
        three1_d6: {
          title: 'Total sheltered count (difference)',
          value: nil,
        },
        three1_d7: {
          title: 'Unsheltered count (difference)',
          value: nil,
        },
        three2_a2: {
          title:  nil,
          value: 'Unduplicated total sheltered homeless persons',
        },
        three2_a3: {
          title: nil,
          value: 'Emergency shelter total',
        },
        three2_a4: {
          title: nil,
          value: 'Safe haven total',
        },
        three2_a5: {
          title: nil,
          value: 'Transitional housing total',
        },
         three2_b1: {
          title: nil,
          value: 'Previous FY',
        },
        three2_b2: {
          title: 'Unduplicated total sheltered homeless persons (previous FY)',
          value: nil,
        },
        three2_b3: {
          title: 'Emergency shelter total (previous FY)',
          value: nil,
        },
        three2_b4: {
          title: 'Safe haven total (previous FY)',
          value: nil,
        },
        three2_b5: {
          title: 'Transitional housing total (previous FY)',
          value: nil,
        },
        three2_c1: {
          title: nil,
          value: 'Current FY',
        },
        three2_c2: { # Total unduplicated ES + SH + TH
          title: 'Unduplicated total sheltered homeless persons (current FY)',
          value: 0,
        },
        three2_c3: { # Total in ES
          title: 'Emergency shelter total (current FY)',
          value: 0,
        },
        three2_c4: { # Total in SH
          title: 'Safe haven total (current FY)',
          value: 0,
        },
        three2_c5: { # Total in TH
          title: 'Transitional housing total (current FY)',
          value: 0,
        },
        three2_d1: {
          title: nil,
          value: 'Difference',
        },
        three2_d2: { # Total unduplicated ES + SH + TH
          title: 'Unduplicated total sheltered homeless persons (difference)',
          value: 0,
        },
        three2_d3: { # Total in ES
          title: 'Emergency shelter total (difference)',
          value: 0,
        },
        three2_d4: { # Total in SH
          title: 'Safe haven total (difference)',
          value: 0,
        },
        three2_d5: { # Total in TH
          title: 'Transitional housing total (difference)',
          value: 0,
        },
      }
    end
  end
end
