module ReportGenerators::SystemPerformance::Fy2016
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
      if start_report(Reports::SystemPerformance::Fy2016::MeasureThree.first)
      
        Rails.logger.info "Starting report #{@report.report.name}"
        @report.update(percent_complete: 0.01)
        # Overview: collect annual counts of homeless persons by sheltering type
        @answers = setup_questions()
        @support = @answers.deep_dup

        # Get totals
        shelter_types = ES + SH + TH
        
        client_scope = GrdaWarehouse::ServiceHistory.service.
          service_within_date_range(start_date: @report.options['report_start'].to_date - 1.day, end_date: @report.options['report_end']).
          hud_project_type(shelter_types)
        client_scope = add_filters(scope: client_scope)
    
        clients = client_scope.
          select(:client_id).
          distinct.
          pluck(:client_id)

        @answers[:three2_c2][:value] = clients.size
        @support[:three2_c2][:support] = {
          headers: ['Client ID'],
          counts: clients.map{|m| [m]}
        }
        
        @report.update(percent_complete: 30, results: @answers, support: @support)
        # sql = "
        #   select distinct client_id, project_type
        #   from hud_performance_client_housing_history
        #   where [date] >= '#{@report.options['report_start']}'
        #     and ([date] < '#{@report.options['report_end']}' or ([date] <= '#{@report.options['report_end']}' and record_type = 'bed_night'))
        # "
        columns = {
          client_id: :client_id, 
          project_type: act_as_project_overlay, 
        }
        client_scope = GrdaWarehouse::ServiceHistory.service.
          joins(:project).
          service_within_date_range(start_date: @report.options['report_start'].to_date - 1.day, end_date: @report.options['report_end'])

        client_scope = add_filters(scope: client_scope)
        
        clients = client_scope.
          select(*columns.values).distinct.
          pluck(*columns.values).map do |row|
            Hash[columns.keys.zip(row)]
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
        # 14: Coordinated Assessment
        es = {}
        sh = {}
        th = {}
        # count each person no more than once per type
        clients.each do |row|
          case row[:project_type]
            when *ES
              es[row[:client_id]] = row[:project_type]
            when *SH
              sh[row[:client_id]] = row[:project_type]
            when *TH
              th[row[:client_id]] = row[:project_type]
          end
        end
        @answers[:three2_c3][:value] = es.size
        @answers[:three2_c4][:value] = sh.size
        @answers[:three2_c5][:value] = th.size

        @support[:three2_c3][:support] = {
          headers: ['Client ID'],
          counts: es.keys.map{|m| [m]}
        }
        @support[:three2_c4][:support] = {
          headers: ['Client ID'],
          counts: sh.keys.map{|m| [m]}
        }
        @support[:three2_c5][:support] = {
          headers: ['Client ID'],
          counts: th.keys.map{|m| [m]}
        }

        Rails.logger.info @answers.inspect
        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end

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
