module ReportGenerators::SystemPerformance::Fy2015
  class MeasureThree
    REPORT_START_DATE = '2014-10-01'
    REPORT_END_DATE = '2015-09-30'
    LOOKBACK_STOP_DATE = '2012-10-01'

    PH = [3,9,10,13]
    TH = [2]
    ES = [1] 
    SH = [8]

    def run!
      tries ||= 0
      # Disable logging so we don't fill the disk
      ActiveRecord::Base.logger.silence do
        begin
          calculate()
        rescue TinyTds::Error => e
          if (tries += 1) < 5
            Rails.logger.warn "Waiting #{tries * 30} seconds to restart"
            sleep (tries * 30)
            Rails.logger.warn 'Restarting, TinyTDS error'
            Rails.logger.warn e.message
            retry
          else
            Rails.logger.warn 'Too many TinyTDS errors, giving up...'
          end       
        end
        Rails.logger.info "Done"
      end # End silence ActiveRecord Log
    end

    private
   
    def calculate
      # Find the first queued report
      report = ReportResult.where(report: Reports::SystemPerformance::Fy2015::MeasureThree.first).where(percent_complete: 0).first
      return unless report.present?
      
      Rails.logger.info "Starting report #{report.report.name}"
      report.update_attributes(percent_complete: 0.01)
      # Overview: collect annual counts of homeless persons by sheltering type
      results = {
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

      # Get totals
      shelter_types = ES + SH + TH
      results[:three2_c2][:value] = GrdaWarehouse::ClientHousingHistory.where("[date] >= '#{REPORT_START_DATE}' and [date] <= '#{REPORT_END_DATE}'").where(record_type: 'bed_night').where(program_type: shelter_types).distinct.count(:unduplicated_client_id)
      
      report.update_attributes(percent_complete: 30)
      # sql = "
      #   select distinct unduplicated_client_id, program_type
      #   from hud_performance_client_housing_history
      #   where [date] >= '#{REPORT_START_DATE}'
      #     and ([date] < '#{REPORT_END_DATE}' or ([date] <= '#{REPORT_END_DATE}' and record_type = 'bed_night'))
      # "
      clients = GrdaWarehouse::ClientHousingHistory.where("[date] >= '#{REPORT_START_DATE}'
          and [date] <= '#{REPORT_END_DATE}' and record_type = 'bed_night'").distinct.select(:unduplicated_client_id, :program_type)
      

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
        case row[:program_type]
          when *ES
            es[row[:unduplicated_client_id]] = row[:program_type]
          when *SH
            sh[row[:unduplicated_client_id]] = row[:program_type]
          when *TH
            th[row[:unduplicated_client_id]] = row[:program_type]
        end
      end
      results[:three2_c3][:value] = es.size
      results[:three2_c4][:value] = sh.size
      results[:three2_c5][:value] = th.size

      Rails.logger.info results.inspect
      # save our progress
      report.update_attributes(percent_complete: 100, results: results, completed_at: Time.now)
      
    end
  end
end
