module ReportGenerators::SystemPerformance::Fy2015
  class MeasureSix
    REPORT_START_DATE = '2014-10-01'
    REPORT_END_DATE = '2015-09-30'
    LOOKBACK_STOP_DATE = '2012-10-01'

    PH = [3,9,10,13]
    TH = [2]
    ES = [1] 
    SH = [8]
    RRH = [13]
    PH_PSH = [3,9,10]
    PERMANENT_DESTINATIONS = [3, 10, 11, 19, 20, 21, 22, 23, 26, 28]
    TEMPORARY_DESTINATIONS = [1, 15, 6, 14, 7, 27, 16, 4, 29, 18, 12, 13, 5, 2, 25]

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
   def connect_to_databases
      grda_warehouse_config = Rails.configuration.database_configuration["#{Rails.env}_grda_warehouse".parameterize.underscore]

      @c_grda_warehouse = TinyTds::Client.new username: grda_warehouse_config['username'], password: grda_warehouse_config['password'], host: grda_warehouse_config['host'], port: grda_warehouse_config['port'], database: grda_warehouse_config['database'], timeout: 300
      @c_grda_warehouse_1 = TinyTds::Client.new username: grda_warehouse_config['username'], password: grda_warehouse_config['password'], host: grda_warehouse_config['host'], port: grda_warehouse_config['port'], database: grda_warehouse_config['database'], timeout: 300
    end

    def calculate
      # TODO: HousingStatusAtEntry & HousingStatusAtExit = 5 -- this is probably where we determine if someone is a Category 3 (value would be 5)
      # This shows up in ProgramParticipation.  No one has HousingStatusAtEntry = 5.  Only at exit
      
      # Note: Dependents do get flagged correctly as Category 3 if attached to a Head of Household
      connect_to_databases()
      # Overview: Returns to homelessness after exit to PH of clients defined by Category 3 (similar to Measure 2 with a smaller sub-set of clients)
      results = {
        sixab_a2: {
          title:  nil,
          value: 'Total number of persons who exited to a permanent housing destination; exit was from SO',
        },
        sixab_a3: {
          title: nil,
          value: 'Total number of persons who exited to a permanent housing destination; exit was from ES',
        },
        sixab_a4: {
          title: nil,
          value: 'Total number of persons who exited to a permanent housing destination; exit was from TH',
        },
        sixab_a5: {
          title: nil,
          value: 'Total number of persons who exited to a permanent housing destination; exit was from SH',
        },
        sixab_a6: {
          title: nil,
          value: 'Total number of persons who exited to a permanent housing destination; exit was from PH',
        },
        sixab_a7: {
          title: nil,
          value: 'Total number of persons who exited to a permanent housing destination; Total retuns to homelessness',
        },
        sixab_b1: {
          title: nil,
          value: 'Total Number of Persons who Exited to a Permanent Housing Destination (2 Years Prior)',
        },
        sixab_b2: {
          title: 'Total number of persons who exited to a permanent housing destination; exit was from SO (2 years prior)',
          value: nil,
        },
        sixab_b3: {
          title: 'Total number of persons who exited to a permanent housing destination; exit was from ES (2 years prior)',
          value: nil,
        },
        sixab_b4: {
          title: 'Total number of persons who exited to a permanent housing destination; exit was from TH (2 years prior)',
          value: 0,
        },
        sixab_b5: {
          title: 'Total number of persons who exited to a permanent housing destination; exit was from SH (2 years prior)',
          value: 0,
        },
        sixab_b6: {
          title: 'Total number of persons who exited to a permanent housing destination; exit was from PH (2 years prior)',
          value: 0,
        },
        sixab_b7: {
          title: 'Total number of persons who exited to a permanent housing destination; Total retuns to homelessness (2 years prior)',
          value: 0,
        },
        sixab_c1: {
          title: nil,
          value: 'Number Returning to Homelessness in Less than 6 Months (0 - 180 days)',
        },
        sixab_c2: {
          title: 'Number returing to homelessness in less than 6 months; exit was from SO (0-180 days) ',
          value: nil,
        },
        sixab_c3: {
          title: 'Number returing to homelessness in less than 6 months; exit was from ES (0-180 days) ',
          value: nil,
        },
        sixab_c4: {
          title: 'Number returing to homelessness in less than 6 months; exit was from TH (0-180 days) ',
          value: 0,
        },
        sixab_c5: {
          title: 'Number returing to homelessness in less than 6 months; exit was from SH (0-180 days) ',
          value: 0,
        },
        sixab_c6: {
          title: 'Number returing to homelessness in less than 6 months; exit was from PH (0-180 days) ',
          value: 0,
        },
        sixab_c7: {
          title: 'Number returing to homelessness in less than 6 months; Total retuns to homelessness (0-180 days) ',
          value: 0,
        },
        sixab_d1: {
          title: nil,
          value: 'Percentage of Returns in Less than 6 Months (0 - 180 days)',
        },
        sixab_d2: {
          title: 'Percentage of returns in less than 6 months; exit was from SO (0-180 days)',
          value: nil,
        },
        sixab_d3: {
          title: 'Percentage of returns in less than 6 months; exit was from ES (0-180 days)',
          value: nil,
        },
        sixab_d4: {
          title: 'Percentage of returns in less than 6 months; exit was from TH (0-180 days)',
          value: 0,
        },
        sixab_d5: {
          title: 'Percentage of returns in less than 6 months; exit was from SH (0-180 days)',
          value: 0,
        },
        sixab_d6: {
          title: 'Percentage of returns in less than 6 months; exit was from PH (0-180 days)',
          value: 0,
        },
        sixab_d7: {
          title: 'Percentage of returns in less than 6 months; Total retuns to homelessness (0-180 days)',
          value: 0,
        },
        sixab_e1: {
          title: nil,
          value: 'Number Returning to Homelessness from 6 to 12 Months (181 - 365 days)',
        },
        sixab_e2: {
          title: 'Number returning to homelessness from 6 to 12 months; exit was from SO (181-365 days)',
          value: nil,
        },
        sixab_e3: {
          title: 'Number returning to homelessness from 6 to 12 months; exit was from ES (181-365 days)',
          value: nil,
        },
        sixab_e4: {
          title: 'Number returning to homelessness from 6 to 12 months; exit was from TH (181-365 days)',
          value: 0,
        },
        sixab_e5: {
          title: 'Number returning to homelessness from 6 to 12 months; exit was from SH (181-365 days)',
          value: 0,
        },
        sixab_e6: {
          title: 'Number returning to homelessness from 6 to 12 months; exit was from PH (181-365 days)',
          value: 0,
        },
        sixab_e7: {
          title: 'Number returning to homelessness from 6 to 12 months; Total retuns to homelessness (181-365 days)',
          value: 0,
        },
        sixab_f1: {
          title: nil,
          value: 'Percentage of Returns from 6 to 12 Months (181 - 365 days)',
        },
        sixab_f2: {
          title: 'Percentage of returns from 6 to 12 months; exit was from SO (181-365 days)',
          value: nil,
        },
        sixab_f3: {
          title: 'Percentage of returns from 6 to 12 months; exit was from ES (181-365 days)',
          value: nil,
        },
        sixab_f4: {
          title: 'Percentage of returns from 6 to 12 months; exit was from TH (181-365 days)',
          value: 0,
        },
        sixab_f5: {
          title: 'Percentage of returns from 6 to 12 months; exit was from SH (181-365 days)',
          value: 0,
        },
        sixab_f6: {
          title: 'Percentage of returns from 6 to 12 months; exit was from PH (181-365 days)',
          value: 0,
        },
        sixab_f7: {
          title: 'Percentage of returns from 6 to 12 months; Total retuns to homelessness (181-365 days)',
          value: 0,
        },
        sixab_g1: {
          title: nil,
          value: 'Number Returning to Homelessness from 13 to 24 Months (366 - 730 days)',
        },
        sixab_g2: {
          title: 'Number returning to homelessness from 13 to 24 months; exit was from SO (366-730 days)',
          value: nil,
        },
        sixab_g3: {
          title: 'Number returning to homelessness from 13 to 24 months; exit was from ES (366-730 days)',
          value: nil,
        },
        sixab_g4: {
          title: 'Number returning to homelessness from 13 to 24 months; exit was from TH (366-730 days)',
          value: 0,
        },
        sixab_g5: {
          title: 'Number returning to homelessness from 13 to 24 months; exit was from SH (366-730 days)',
          value: 0,
        },
        sixab_g6: {
          title: 'Number returning to homelessness from 13 to 24 months; exit was from PH (366-730 days)',
          value: 0,
        },
        sixab_g7: {
          title: 'Number returning to homelessness from 13 to 24 months; Total retuns to homelessness (366-730 days)',
          value: 0,
        },
        sixab_h1: {
          title: nil,
          value: 'Percentage of Returns from 13 to 24 Months (366 - 730 days)',
        },
        sixab_h2: {
          title: 'Percentage of returns from 13 to 24 months; exit was from SO (366-730 days)',
          value: nil,
        },
        sixab_h3: {
          title: 'Percentage of returns from 13 to 24 months; exit was from ES (366-730 days)',
          value: nil,
        },
        sixab_h4: {
          title: 'Percentage of returns from 13 to 24 months; exit was from TH (366-730 days)',
          value: 0,
        },
        sixab_h5: {
          title: 'Percentage of returns from 13 to 24 months; exit was from SH (366-730 days)',
          value: 0,
        },
        sixab_h6: {
          title: 'Percentage of returns from 13 to 24 months; exit was from PH (366-730 days)',
          value: 0,
        },
        sixab_h7: {
          title: 'Percentage of returns from 13 to 24 months; Total retuns to homelessness (366-730 days)',
          value: 0,
        },
        sixab_i1: {
          title: nil,
          value: 'Number of Returns in 2 Years',
        },
        sixab_i2: {
          title: 'Number of returns in 2 years; exit was from SO',
          value: nil,
        },
        sixab_i3: {
          title: 'Number of returns in 2 years; exit was from ES',
          value: nil,
        },
        sixab_i4: {
          title: 'Number of returns in 2 years; exit was from TH',
          value: 0,
        },
        sixab_i5: {
          title: 'Number of returns in 2 years; exit was from SH',
          value: 0,
        },
        sixab_i6: {
          title: 'Number of returns in 2 years; exit was from PH',
          value: 0,
        },
        sixab_i7: {
          title: 'Number of returns in 2 years; Total retuns to homelessness',
          value: 0,
        },
        sixab_j1: {
          title: nil,
          value: 'Percentage of Returns in 2 Years',
        },
        sixab_j2: {
          title: 'Percentage of returns in 2 years; exit was from SO',
          value: nil,
        },
        sixab_j3: {
          title: 'Percentage of returns in 2 years; exit was from ES',
          value: nil,
        },
        sixab_j4: {
          title: 'Percentage of returns in 2 years; exit was from TH',
          value: 0,
        },
        sixab_j5: {
          title: 'Percentage of returns in 2 years; exit was from SH',
          value: 0,
        },
        sixab_j6: {
          title: 'Percentage of returns in 2 years; exit was from PH',
          value: 0,
        },
        sixab_j7: {
          title: 'Percentage of returns in 2 years; Total retuns to homelessness',
          value: 0,
        },
        sixc1_a2: {
          title:  nil,
          value: 'Universe: Cat. 3 SH, TH and PH-RRH system leavers',
        },
        sixc1_a3: {
          title: nil,
          value: 'Of the persons above, those who exited to permanent destinations',
        },
        sixc1_a4: {
          title: nil,
          value: '% successful exits',
        },
        sixc1_b1: {
          title: nil,
          value: 'Previous FY',
        },
        sixc1_b2: {
          title: 'Universe: Cat. 3 SH, TH and PH-RRH system leavers (previous FY)',
          value: nil,
        },
        sixc1_b3: {
          title: 'Of the persons above, those who exited to permanent destinations (previous FY)',
          value: nil,
        },
        sixc1_b4: {
          title: '% successful exits (previous FY)',
          value: nil,
        },
        sixc1_c1: {
          title: nil,
          value: 'Current FY',
        },
        sixc1_c2: {
          title: 'Universe: Cat. 3 SH, TH and PH-RRH system leavers (current FY)',
          value: 0,
        },
        sixc1_c3: {
          title: 'Of the persons above, those who exited to permanent destinations (current FY)',
          value: 0,
        },
        sixc1_c4: {
          title: '% successful exits (current FY)',
          value: 0,
        },
        sixc1_d1: {
          title: nil,
          value: 'Difference',
        },
        sixc1_d2: {
          title: 'Universe: Cat. 3 SH, TH and PH-RRH system leavers (difference)',
          value: nil,
        },
        sixc1_d3: {
          title: 'Of the persons above, those who exited to permanent destinations (difference)',
          value: nil,
        },
        sixc1_d4: {
          title: '% successful exits (difference)',
          value: nil,
        },
        sixc2_a2: {
          title:  nil,
          value: 'Universe: Cat. 3 PH-PSH system stayers and leavers',
        },
        sixc2_a3: {
          title: nil,
          value: 'Of persons above, count those who remained in PH-PSH projects and those who exited to permanent housing destinations',
        },
        sixc2_a4: {
          title: nil,
          value: '% successful exits',
        },
        sixc2_b1: {
          title: nil,
          value: 'Previous FY',
        },
        sixc2_b2: {
          title: 'Universe: Cat. 3 PH-PSH system stayers and leavers (previous FY)',
          value: nil,
        },
        sixc2_b3: {
          title: 'Of persons above, count those who remained in PH-PSH projects and those who exited to permanent housing destinations (previous FY)',
          value: nil,
        },
        sixc2_b4: {
          title: '% Successul exits/retention (previous FY)',
          value: nil,
        },
        sixc2_c1: {
          title: nil,
          value: 'Current FY',
        },
        sixc2_c2: {
          title: 'Universe: Cat. 3 PH-PSH system stayers and leavers (current FY)',
          value: 0,
        },
        sixc2_c3: {
          title: 'Of persons above, count those who remained in PH-PSH projects and those who exited to permanent housing destinations (current FY)',
          value: 0,
        },
        sixc2_c4: {
          title: '% Successul exits/retention (current FY)',
          value: 0,
        },
        sixc2_d1: {
          title: nil,
          value: 'Difference',
        },
        sixc2_d2: {
          title: 'Universe: Cat. 3 PH-PSH system stayers and leavers (difference)',
          value: nil,
        },
        sixc2_d3: {
          title: 'Of persons above, count those who remained in PH-PSH projects and those who exited to permanent housing destinations (difference)',
          value: nil,
        },
        sixc2_d4: {
          title: '% Successul exits/retention (difference)',
          value: nil,
        },
      }

      # Find the first queued report
      report = ReportResult.where(report: Reports::SystemPerformance::Fy2015::MeasureSix.first).where(percent_complete: 0).first
      return unless report.present?

      Rails.logger.info "Starting report #{report.report.name}"
      report.update_attributes(percent_complete: 1)
      results.merge!(measure_6_a_and_b)
      report.update_attributes(percent_complete: 33)
      results.merge!(measure_6c_1)
      report.update_attributes(percent_complete: 66)
      results.merge!(measure_6c_2)
      report.update_attributes(percent_complete: 99)

      Rails.logger.info results
      # save our progress
      report.update_attributes(percent_complete: 100, results: results, completed_at: Time.now)

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
            
    end

    def measure_6_a_and_b
      results = {  
        sixab_b2: {
          title: 'Total number of persons who exited to a permanent housing destination; exit was from SO (2 years prior)',
          value: nil,
        },
        sixab_b3: {
          title: 'Total number of persons who exited to a permanent housing destination; exit was from ES (2 years prior)',
          value: nil,
        },
        sixab_b4: {
          title: 'Total number of persons who exited to a permanent housing destination; exit was from TH (2 years prior)',
          value: 0,
        },
        sixab_b5: {
          title: 'Total number of persons who exited to a permanent housing destination; exit was from SH (2 years prior)',
          value: 0,
        },
        sixab_b6: {
          title: 'Total number of persons who exited to a permanent housing destination; exit was from PH (2 years prior)',
          value: 0,
        },
        sixab_b7: {
          title: 'Total number of persons who exited to a permanent housing destination; Total retuns to homelessness (2 years prior)',
          value: 0,
        },
        sixab_c2: {
          title: 'Number returing to homelessness in less than 6 months; exit was from SO (0-180 days) ',
          value: nil,
        },
        sixab_c3: {
          title: 'Number returing to homelessness in less than 6 months; exit was from ES (0-180 days) ',
          value: nil,
        },
        sixab_c4: {
          title: 'Number returing to homelessness in less than 6 months; exit was from TH (0-180 days) ',
          value: 0,
        },
        sixab_c5: {
          title: 'Number returing to homelessness in less than 6 months; exit was from SH (0-180 days) ',
          value: 0,
        },
        sixab_c6: {
          title: 'Number returing to homelessness in less than 6 months; exit was from PH (0-180 days) ',
          value: 0,
        },
        sixab_c7: {
          title: 'Number returing to homelessness in less than 6 months; Total retuns to homelessness (0-180 days) ',
          value: 0,
        },
        sixab_d2: {
          title: 'Percentage of returns in less than 6 months; exit was from SO (0-180 days)',
          value: nil,
        },
        sixab_d3: {
          title: 'Percentage of returns in less than 6 months; exit was from ES (0-180 days)',
          value: nil,
        },
        sixab_d4: {
          title: 'Percentage of returns in less than 6 months; exit was from TH (0-180 days)',
          value: 0,
        },
        sixab_d5: {
          title: 'Percentage of returns in less than 6 months; exit was from SH (0-180 days)',
          value: 0,
        },
        sixab_d6: {
          title: 'Percentage of returns in less than 6 months; exit was from PH (0-180 days)',
          value: 0,
        },
        sixab_d7: {
          title: 'Percentage of returns in less than 6 months; Total retuns to homelessness (0-180 days)',
          value: 0,
        },
        sixab_e2: {
          title: 'Number returning to homelessness from 6 to 12 months; exit was from SO (181-365 days)',
          value: nil,
        },
        sixab_e3: {
          title: 'Number returning to homelessness from 6 to 12 months; exit was from ES (181-365 days)',
          value: nil,
        },
        sixab_e4: {
          title: 'Number returning to homelessness from 6 to 12 months; exit was from TH (181-365 days)',
          value: 0,
        },
        sixab_e5: {
          title: 'Number returning to homelessness from 6 to 12 months; exit was from SH (181-365 days)',
          value: 0,
        },
        sixab_e6: {
          title: 'Number returning to homelessness from 6 to 12 months; exit was from PH (181-365 days)',
          value: 0,
        },
        sixab_e7: {
          title: 'Number returning to homelessness from 6 to 12 months; Total retuns to homelessness (181-365 days)',
          value: 0,
        },
        sixab_f2: {
          title: 'Percentage of returns from 6 to 12 months; exit was from SO (181-365 days)',
          value: nil,
        },
        sixab_f3: {
          title: 'Percentage of returns from 6 to 12 months; exit was from ES (181-365 days)',
          value: nil,
        },
        sixab_f4: {
          title: 'Percentage of returns from 6 to 12 months; exit was from TH (181-365 days)',
          value: 0,
        },
        sixab_f5: {
          title: 'Percentage of returns from 6 to 12 months; exit was from SH (181-365 days)',
          value: 0,
        },
        sixab_f6: {
          title: 'Percentage of returns from 6 to 12 months; exit was from PH (181-365 days)',
          value: 0,
        },
        sixab_f7: {
          title: 'Percentage of returns from 6 to 12 months; Total retuns to homelessness (181-365 days)',
          value: 0,
        },
        sixab_g2: {
          title: 'Number returning to homelessness from 13 to 24 months; exit was from SO (366-730 days)',
          value: nil,
        },
        sixab_g3: {
          title: 'Number returning to homelessness from 13 to 24 months; exit was from ES (366-730 days)',
          value: nil,
        },
        sixab_g4: {
          title: 'Number returning to homelessness from 13 to 24 months; exit was from TH (366-730 days)',
          value: 0,
        },
        sixab_g5: {
          title: 'Number returning to homelessness from 13 to 24 months; exit was from SH (366-730 days)',
          value: 0,
        },
        sixab_g6: {
          title: 'Number returning to homelessness from 13 to 24 months; exit was from PH (366-730 days)',
          value: 0,
        },
        sixab_g7: {
          title: 'Number returning to homelessness from 13 to 24 months; Total retuns to homelessness (366-730 days)',
          value: 0,
        },
        sixab_h2: {
          title: 'Percentage of returns from 13 to 24 months; exit was from SO (366-730 days)',
          value: nil,
        },
        sixab_h3: {
          title: 'Percentage of returns from 13 to 24 months; exit was from ES (366-730 days)',
          value: nil,
        },
        sixab_h4: {
          title: 'Percentage of returns from 13 to 24 months; exit was from TH (366-730 days)',
          value: 0,
        },
        sixab_h5: {
          title: 'Percentage of returns from 13 to 24 months; exit was from SH (366-730 days)',
          value: 0,
        },
        sixab_h6: {
          title: 'Percentage of returns from 13 to 24 months; exit was from PH (366-730 days)',
          value: 0,
        },
        sixab_h7: {
          title: 'Percentage of returns from 13 to 24 months; Total retuns to homelessness (366-730 days)',
          value: 0,
        },
        sixab_i2: {
          title: 'Number of returns in 2 years; exit was from SO',
          value: nil,
        },
        sixab_i3: {
          title: 'Number of returns in 2 years; exit was from ES',
          value: nil,
        },
        sixab_i4: {
          title: 'Number of returns in 2 years; exit was from TH',
          value: 0,
        },
        sixab_i5: {
          title: 'Number of returns in 2 years; exit was from SH',
          value: 0,
        },
        sixab_i6: {
          title: 'Number of returns in 2 years; exit was from PH',
          value: 0,
        },
        sixab_i7: {
          title: 'Number of returns in 2 years; Total retuns to homelessness',
          value: 0,
        },
        sixab_j2: {
          title: 'Percentage of returns in 2 years; exit was from SO',
          value: nil,
        },
        sixab_j3: {
          title: 'Percentage of returns in 2 years; exit was from ES',
          value: nil,
        },
        sixab_j4: {
          title: 'Percentage of returns in 2 years; exit was from TH',
          value: 0,
        },
        sixab_j5: {
          title: 'Percentage of returns in 2 years; exit was from SH',
          value: 0,
        },
        sixab_j6: {
          title: 'Percentage of returns in 2 years; exit was from PH',
          value: 0,
        },
        sixab_j7: {
          title: 'Percentage of returns in 2 years; Total retuns to homelessness',
          value: 0,
        },
      }
      project_types = TH + SH + PH 
      look_back_until =  LOOKBACK_STOP_DATE.to_date >= (REPORT_START_DATE.to_date - 730.days) ? LOOKBACK_STOP_DATE : (REPORT_START_DATE.to_date - 730.days).strftime('%Y-%m-%d')
      look_forward_until = (REPORT_END_DATE.to_date - 730.days).strftime('%Y-%m-%d')

      project_exits_universe = GrdaWarehouse::ClientHousingHistory.where("record_type = 'exit'
        and last_date_in_program <= '#{look_forward_until}'
        and last_date_in_program >= '#{look_back_until}'
        and (housing_status_at_entry = 5 or housing_status_at_exit = 5) -- Limit to Category 3 --
        and program_type in (#{project_types.compact.join(', ')})").order(unduplicated_client_id: :asc).order(last_date_in_program: :asc).select(:unduplicated_client_id, :destination, :date, :first_date_in_program, :last_date_in_program, :program_type, :program_id)
      project_exits_to_ph = {}
      project_exists_from = {so: [], es: [], th: [], sh: [], ph: []}
      # Loop over exits
      # If we find an exit with a destination in (3, 10, 11, 19, 20, 21, 22, 23, 26, 28)
      # log the earliest instance of each client (first exit to PH)
      project_exits_universe.each do |p_exit|
        if PERMANENT_DESTINATIONS.include? p_exit[:destination] 
          if project_exits_to_ph[p_exit[:unduplicated_client_id]].nil?
            project_exits_to_ph[p_exit[:unduplicated_client_id]] = p_exit
          end
        end
      end
      project_exits_to_ph.each do |id, p_exit|
        case p_exit[:program_type].to_i
          when *SO
            project_exists_from[:so] << p_exit
          when *ES 
            project_exists_from[:es] << p_exit
          when *TH
            project_exists_from[:th] << p_exit
          when *SH
            project_exists_from[:sh] << p_exit
          when *PH
            project_exists_from[:ph] << p_exit
        end
      end
      results[:sixab_b2][:value] = project_exists_from[:so].count
      results[:sixab_b3][:value] = project_exists_from[:es].count
      results[:sixab_b4][:value] = project_exists_from[:th].count
      results[:sixab_b5][:value] = project_exists_from[:sh].count
      results[:sixab_b6][:value] = project_exists_from[:ph].count
      results[:sixab_b7][:value] = results[:sixab_b2][:value] + results[:sixab_b3][:value] + results[:sixab_b4][:value] + results[:sixab_b5][:value] + results[:sixab_b6][:value]

      # Find anyone who has returned to homelessness after 14+ days
      # Find their first return to homelessness and calculate the days between the 
      # time they exited to PH and returned to homelessness
      # Note: if the next entry is to a TH, the entry must be 14 days after the original
      # exit to count
      # Note: if the next entry is to a PH, it is only counted if it occurs more than 14 
      # days after the original exit, or more than 14 days after a TH
      project_exit_counts = {
        c_0_180_days: {so: [], es: [], th: [], sh: [], ph: []},
        e_181_365_days: {so: [], es: [], th: [], sh: [], ph: []}, 
        g_366_730_days: {so: [], es: [], th: [], sh: [], ph: []}
      }
      project_exits_to_ph.each do |id, p_exit|
        client_entries = {}
        client_entries_all = GrdaWarehouse::ClientHousingHistory.where("record_type = 'entry'
          and first_date_in_program <= '#{REPORT_END_DATE}'
          and first_date_in_program > '#{p_exit[:last_date_in_program].strftime('%Y-%m-%d')}'
          and unduplicated_client_id = #{p_exit[:unduplicated_client_id]}").order(date: :asc).select(:unduplicated_client_id, :destination, :date, :first_date_in_program, :last_date_in_program, :program_type, :program_id)
        # Build a useful universe of entries
        # Make note of project type each day, PH will take priority over TH which is > else
        client_entries_all.each do |entry|
          if client_entries[entry[:first_date_in_program]].nil?
            client_entries[entry[:first_date_in_program]] = []
          end
          client_entries[entry[:first_date_in_program]] << case entry[:program_type]
            when *SO
               'SO'
            when *ES 
              'ES'
            when *TH
              'TH'
            when *SH
              'SH'
            when *PH
              'PH'
          end
        end
        # Priority PH > TH > Other 
        # NOTE: we'll set a check-date for permanent housing.  If you exit PH within 14 days of this, we don't count it, 
        # but update the date.  If we ever have an exit from permanent housing longer than 14 days after the check
        # date, we count it
        ph_check_date = p_exit[:last_date_in_program].to_date 
        client_entries.each do |day, program_types|
          day_count = (day.to_date - p_exit[:last_date_in_program].to_date).to_i
          # If the entry doesn't contain PH or TH, count it and move on
          if program_types.exclude?('PH') && program_types.exclude?('TH')
            case day_count
            when (0..180)
              case p_exit[:program_type].to_i
                when *SO
                  project_exit_counts[:c_0_180_days][:so] << day_count
                when *ES 
                  project_exit_counts[:c_0_180_days][:es] << day_count
                when *TH
                  project_exit_counts[:c_0_180_days][:th] << day_count
                when *SH
                  project_exit_counts[:c_0_180_days][:sh] << day_count
                when *PH
                  project_exit_counts[:c_0_180_days][:ph] << day_count
              end
            when (181..365)
              case p_exit[:program_type].to_i
                when *SO
                  project_exit_counts[:e_181_365_days][:so] << day_count
                when *ES 
                  project_exit_counts[:e_181_365_days][:es] << day_count
                when *TH
                  project_exit_counts[:e_181_365_days][:th] << day_count
                when *SH
                  project_exit_counts[:e_181_365_days][:sh] << day_count
                when *PH
                  project_exit_counts[:e_181_365_days][:ph] << day_count
              end
            when (367..730)
              case p_exit[:program_type].to_i
                when *SO
                  project_exit_counts[:g_366_730_days][:so] << day_count
                when *ES 
                  project_exit_counts[:g_366_730_days][:es] << day_count
                when *TH
                  project_exit_counts[:g_366_730_days][:th] << day_count
                when *SH
                  project_exit_counts[:g_366_730_days][:sh] << day_count
                when *PH
                  project_exit_counts[:g_366_730_days][:ph] << day_count
              end
            end
            break # stop counting for this client

          elsif program_types.include?('PH')
            if (day.to_date - ph_check_date).to_i < 14
              next_end_date = GrdaWarehouse::ClientHousingHistory.where("record_type = 'entry'
                and first_date_in_program = '#{day}'
                and unduplicated_client_id = #{p_exit[:unduplicated_client_id]}
                and program_type in #{PH.join(',')}
                ").order(last_date_in_program: :desc).limit(1).pluck(:last_date_in_program).first
              if next_end_date.nil?
                break
              end
              ph_check_date = next_end_date
            else
              case day_count
              when (0..180)
                case p_exit[:program_type].to_i
                  when *SO
                    project_exit_counts[:c_0_180_days][:so] << day_count
                  when *ES 
                    project_exit_counts[:c_0_180_days][:es] << day_count
                  when *TH
                    project_exit_counts[:c_0_180_days][:th] << day_count
                  when *SH
                    project_exit_counts[:c_0_180_days][:sh] << day_count
                  when *PH
                    project_exit_counts[:c_0_180_days][:ph] << day_count
                end
              when (181..365)
                case p_exit[:program_type].to_i
                  when *SO
                    project_exit_counts[:e_181_365_days][:so] << day_count
                  when *ES 
                    project_exit_counts[:e_181_365_days][:es] << day_count
                  when *TH
                    project_exit_counts[:e_181_365_days][:th] << day_count
                  when *SH
                    project_exit_counts[:e_181_365_days][:sh] << day_count
                  when *PH
                    project_exit_counts[:e_181_365_days][:ph] << day_count
                end
              when (367..730)
                case p_exit[:program_type].to_i
                  when *SO
                    project_exit_counts[:g_366_730_days][:so] << day_count
                  when *ES 
                    project_exit_counts[:g_366_730_days][:es] << day_count
                  when *TH
                    project_exit_counts[:g_366_730_days][:th] << day_count
                  when *SH
                    project_exit_counts[:g_366_730_days][:sh] << day_count
                  when *PH
                    project_exit_counts[:g_366_730_days][:ph] << day_count
                end
              end
              break # stop counting for this client
            end
            # If the next destination is TH, it must be > 14 days since exit to count
          elsif program_types.include?('TH')
            if day_count > 14
              case day_count
              when (0..180)
                case p_exit[:program_type].to_i
                  when *SO
                    project_exit_counts[:c_0_180_days][:so] << day_count
                  when *ES 
                    project_exit_counts[:c_0_180_days][:es] << day_count
                  when *TH
                    project_exit_counts[:c_0_180_days][:th] << day_count
                  when *SH
                    project_exit_counts[:c_0_180_days][:sh] << day_count
                  when *PH
                    project_exit_counts[:c_0_180_days][:ph] << day_count
                end
              when (181..365)
                case p_exit[:program_type].to_i
                  when *SO
                    project_exit_counts[:e_181_365_days][:so] << day_count
                  when *ES 
                    project_exit_counts[:e_181_365_days][:es] << day_count
                  when *TH
                    project_exit_counts[:e_181_365_days][:th] << day_count
                  when *SH
                    project_exit_counts[:e_181_365_days][:sh] << day_count
                  when *PH
                    project_exit_counts[:e_181_365_days][:ph] << day_count
                end
              when (367..730)
                case p_exit[:program_type].to_i
                  when *SO
                    project_exit_counts[:g_366_730_days][:so] << day_count
                  when *ES 
                    project_exit_counts[:g_366_730_days][:es] << day_count
                  when *TH
                    project_exit_counts[:g_366_730_days][:th] << day_count
                  when *SH
                    project_exit_counts[:g_366_730_days][:sh] << day_count
                  when *PH
                    project_exit_counts[:g_366_730_days][:ph] << day_count
                end
              end
              break # stop counting for this client
            end
          end
        end
      end
      results[:sixab_c2][:value] = project_exit_counts[:c_0_180_days][:so].count
      results[:sixab_c3][:value] = project_exit_counts[:c_0_180_days][:es].count
      results[:sixab_c4][:value] = project_exit_counts[:c_0_180_days][:th].count
      results[:sixab_c5][:value] = project_exit_counts[:c_0_180_days][:sh].count
      results[:sixab_c6][:value] = project_exit_counts[:c_0_180_days][:ph].count
      results[:sixab_e2][:value] = project_exit_counts[:e_181_365_days][:so].count
      results[:sixab_e3][:value] = project_exit_counts[:e_181_365_days][:es].count
      results[:sixab_e4][:value] = project_exit_counts[:e_181_365_days][:th].count
      results[:sixab_e5][:value] = project_exit_counts[:e_181_365_days][:sh].count
      results[:sixab_e6][:value] = project_exit_counts[:e_181_365_days][:ph].count
      results[:sixab_g2][:value] = project_exit_counts[:g_366_730_days][:so].count
      results[:sixab_g3][:value] = project_exit_counts[:g_366_730_days][:es].count
      results[:sixab_g4][:value] = project_exit_counts[:g_366_730_days][:th].count
      results[:sixab_g5][:value] = project_exit_counts[:g_366_730_days][:sh].count
      results[:sixab_g6][:value] = project_exit_counts[:g_366_730_days][:ph].count

      # simple math
      results[:sixab_c7][:value] = results[:sixab_c2][:value] + results[:sixab_c3][:value] + results[:sixab_c4][:value] + results[:sixab_c5][:value] + results[:sixab_c6][:value]
      results[:sixab_e7][:value] = results[:sixab_e2][:value] + results[:sixab_e3][:value] + results[:sixab_e4][:value] + results[:sixab_e5][:value] + results[:sixab_e6][:value]
      results[:sixab_g7][:value] = results[:sixab_g2][:value] + results[:sixab_g3][:value] + results[:sixab_g4][:value] + results[:sixab_g5][:value] + results[:sixab_g6][:value]
      
      # results[:sixab_d2][:value] = ((results[:sixab_c2][:value].to_f / results[:sixab_b2][:value]) * 100).round(2)
      # results[:sixab_d3][:value] = ((results[:sixab_c3][:value].to_f / results[:sixab_b3][:value]) * 100).round(2)
      results[:sixab_d4][:value] = ((results[:sixab_c4][:value].to_f / results[:sixab_b4][:value]) * 100).round(2)
      results[:sixab_d5][:value] = ((results[:sixab_c5][:value].to_f / results[:sixab_b5][:value]) * 100).round(2)
      results[:sixab_d6][:value] = ((results[:sixab_c6][:value].to_f / results[:sixab_b6][:value]) * 100).round(2)
      results[:sixab_d7][:value] = ((results[:sixab_c7][:value].to_f / results[:sixab_b7][:value]) * 100).round(2)

      # results[:sixab_f2][:value] = ((results[:sixab_e2][:value].to_f / results[:sixab_b2][:value]) * 100).round(2)
      # results[:sixab_f3][:value] = ((results[:sixab_e3][:value].to_f / results[:sixab_b3][:value]) * 100).round(2)
      results[:sixab_f4][:value] = ((results[:sixab_e4][:value].to_f / results[:sixab_b4][:value]) * 100).round(2)
      results[:sixab_f5][:value] = ((results[:sixab_e5][:value].to_f / results[:sixab_b5][:value]) * 100).round(2)
      results[:sixab_f6][:value] = ((results[:sixab_e6][:value].to_f / results[:sixab_b6][:value]) * 100).round(2)
      results[:sixab_f7][:value] = ((results[:sixab_e7][:value].to_f / results[:sixab_b7][:value]) * 100).round(2)

      # results[:sixab_h2][:value] = ((results[:sixab_g2][:value].to_f / results[:sixab_b2][:value]) * 100).round(2)
      # results[:sixab_h3][:value] = ((results[:sixab_g3][:value].to_f / results[:sixab_b3][:value]) * 100).round(2)
      results[:sixab_h4][:value] = ((results[:sixab_g4][:value].to_f / results[:sixab_b4][:value]) * 100).round(2)
      results[:sixab_h5][:value] = ((results[:sixab_g5][:value].to_f / results[:sixab_b5][:value]) * 100).round(2)
      results[:sixab_h6][:value] = ((results[:sixab_g6][:value].to_f / results[:sixab_b6][:value]) * 100).round(2)
      results[:sixab_h7][:value] = ((results[:sixab_g7][:value].to_f / results[:sixab_b7][:value]) * 100).round(2)

      # results[:sixab_i2][:value] = results[:sixab_c2][:value] + results[:sixab_e2][:value] + results[:sixab_g2][:value]
      # results[:sixab_i3][:value] = results[:sixab_c3][:value] + results[:sixab_e3][:value] + results[:sixab_g2][:value]
      results[:sixab_i4][:value] = results[:sixab_c4][:value] + results[:sixab_e4][:value] + results[:sixab_g4][:value]
      results[:sixab_i5][:value] = results[:sixab_c5][:value] + results[:sixab_e5][:value] + results[:sixab_g5][:value]
      results[:sixab_i6][:value] = results[:sixab_c6][:value] + results[:sixab_e6][:value] + results[:sixab_g6][:value]
      results[:sixab_i7][:value] = results[:sixab_c7][:value] + results[:sixab_e7][:value] + results[:sixab_g7][:value]

      # results[:sixab_j2][:value] = ((results[:sixab_i2][:value].to_f / results[:sixab_b2][:value]) * 100).round(2)
      # results[:sixab_j3][:value] = ((results[:sixab_i3][:value].to_f / results[:sixab_b3][:value]) * 100).round(2)
      results[:sixab_j4][:value] = ((results[:sixab_i4][:value].to_f / results[:sixab_b4][:value]) * 100).round(2)
      results[:sixab_j5][:value] = ((results[:sixab_i5][:value].to_f / results[:sixab_b5][:value]) * 100).round(2)
      results[:sixab_j6][:value] = ((results[:sixab_i6][:value].to_f / results[:sixab_b6][:value]) * 100).round(2)
      results[:sixab_j7][:value] = ((results[:sixab_i7][:value].to_f / results[:sixab_b7][:value]) * 100).round(2)
      return results
    end

    def measure_6c_1
      results = {
        sixc1_c2: {
          title: 'Universe: Cat. 3 SH, TH and PH-RRH system leavers (current FY)',
          value: 0,
        },
        sixc1_c3: {
          title: 'Of the persons above, those who exited to permanent destinations (current FY)',
          value: 0,
        },
        sixc1_c4: {
          title: '% successful exits (current FY)',
          value: 0,
        },
      }
      # Select clients who have a recorded stay in  SH, TH and PH-RRH during the report period and who are Category 3
      # who also don't have a "bed-night" at an SH, TH and PH-RRH on the final day of the report 
      # eg. Those who were counted by SH, TH and PH-RRH, but exited to somewhere else
      sql = "
        select distinct unduplicated_client_id
        from #{GrdaWarehouse::ClientHousingHistory.table_name}
        where program_type in (#{(SH + TH + RRH).compact.join(', ')})
          and record_type = 'exit'
          and (housing_status_at_entry = 5 or housing_status_at_exit = 5) -- Limit to Category 3 --
          and [date] >= '#{REPORT_START_DATE}'
          and [date] <= '#{REPORT_END_DATE}'
          and unduplicated_client_id not in (
            select distinct unduplicated_client_id
            from #{GrdaWarehouse::ClientHousingHistory.table_name}
            where program_type in (#{(SH + TH + RRH).compact.join(', ')})
              and record_type = 'bed_night'
              and [date] = '#{REPORT_END_DATE}'
          )
      "
      universe = @c_grda_warehouse.execute(sql).each.map{|m| m["unduplicated_client_id"]}
      destinations = {}
      universe.each do |id| 
        sql = "
          select top 1 destination
          from #{GrdaWarehouse::ClientHousingHistory.table_name}
          where unduplicated_client_id = #{id}
            and program_type in (#{(SH + TH + RRH).compact.join(', ')})
            and record_type = 'exit'
            and [date] >= '#{REPORT_START_DATE}'
            and [date] <= '#{REPORT_END_DATE}'
          order by [date] desc
        "
        destinations[id] = @c_grda_warehouse_1.execute(sql).each.first["destination"]
      end
      remaining_leavers = destinations.reject{ |k,v| [15, 6,25,24].include?(v.to_i)}
      results[:sixc1_c2][:value] = remaining_leavers.size
      permanent_leavers = destinations.select{ |k,v| [26, 11, 21, 3, 10, 28, 20, 19, 22, 23].include?(v.to_i)}
      results[:sixc1_c3][:value] = permanent_leavers.size
      results[:sixc1_c4][:value] = ((results[:sixc1_c3][:value].to_f / results[:sixc1_c2][:value]) * 100).round(2)
      return results
    end

    def measure_6c_2
      results = {
        sixc2_c2: {
          title: 'Universe: Cat. 3 PH-PSH system stayers and leavers (current FY)',
          value: 0,
        },
        sixc2_c3: {
          title: 'Of persons above, count those who remained in PH-PSH projects and those who exited to permanent housing destinations (current FY)',
          value: 0,
        },
        sixc2_c4: {
          title: '% Successul exits/retention (current FY)',
          value: 0,
        },
      }
      # Select clients who have a recorded stay in PH but not PH-RRH during the report period
      # who also don't have a "bed-night" at a PH but not PH-RRH on the final day of the report 
      # eg. Those who were counted by PH but not PH-RRH, but exited to somewhere else
      
      sql = "
        select distinct unduplicated_client_id
        from #{GrdaWarehouse::ClientHousingHistory.table_name}
        where  program_type in (#{(PH_PSH).compact.join(', ')})
          and record_type = 'exit'
          and (housing_status_at_entry = 5 or housing_status_at_exit = 5) -- Limit to Category 3 --
          and [date] >= '#{REPORT_START_DATE}'
          and [date] <= '#{REPORT_END_DATE}'
          and unduplicated_client_id not in (
            select distinct unduplicated_client_id
            from #{GrdaWarehouse::ClientHousingHistory.table_name}
            where program_type in (#{(PH_PSH).compact.join(', ')})
              and record_type = 'bed_night'
              and [date] = '#{REPORT_END_DATE}'
          )
      "
      leavers = @c_grda_warehouse.execute(sql).each.map{|m| m["unduplicated_client_id"]}
      sql = "
        select distinct unduplicated_client_id
        from #{GrdaWarehouse::ClientHousingHistory.table_name}
        where  program_type in (#{(PH_PSH).compact.join(', ')})
          and record_type = 'bed_night'
          and [date] = '#{REPORT_END_DATE}'
          and unduplicated_client_id in (
            select unduplicated_client_id from #{GrdaWarehouse::ClientHousingHistory.table_name}
            where program_type in (#{(PH_PSH).compact.join(', ')})
              and first_date_in_program <= '#{REPORT_END_DATE}'
              and record_type = 'entry'
              and (housing_status_at_entry = 5 or housing_status_at_exit = 5) -- Limit to Category 3 --
          )
      "
      stayers = @c_grda_warehouse.execute(sql).each.map{|m| m["unduplicated_client_id"]} - leavers
      destinations = {}
      leavers.each do |id| 
        sql = "
          select top 1 destination
          from #{GrdaWarehouse::ClientHousingHistory.table_name}
          where  unduplicated_client_id = #{id}
            and program_type in (#{(PH).compact.join(', ')})
            and record_type = 'exit'
            and [date] >= '#{REPORT_START_DATE}'
            and [date] <= '#{REPORT_END_DATE}'
          order by [date] desc
        "
        destinations[id] = @c_grda_warehouse_1.execute(sql).each.first["destination"]
      end
      remaining_leavers = destinations.reject{ |k,v| [15, 6,25,24].include?(v.to_i)}
      results[:sixc2_c2][:value] = remaining_leavers.size + stayers.size
      permanent_leavers = destinations.select{ |k,v| [26, 11, 21, 3, 10, 28, 20, 19, 22, 23].include?(v.to_i)}
      results[:sixc2_c3][:value] = permanent_leavers.size + stayers.size
      results[:sixc2_c4][:value] = ((results[:sixc2_c3][:value].to_f / results[:sixc2_c2][:value]) * 100).round(2)
      return results
    end
  end
end
