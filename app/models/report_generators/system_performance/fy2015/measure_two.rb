module ReportGenerators::SystemPerformance::Fy2015
  class MeasureTwo
    REPORT_START_DATE = '2014-10-01'
    REPORT_END_DATE = '2015-09-30'
    LOOKBACK_STOP_DATE = '2012-10-01'


    PH = [3,9,10,13]
    TH = [2]
    ES = [1] 
    SH = [8]
    SO = [4]
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
      config = Rails.configuration.database_configuration["#{Rails.env}_old_warehouse".parameterize.underscore]
      @c0 = TinyTds::Client.new username: config['username'], password: config['password'], host: config['host'], port: config['port'], database: config['database'], timeout: 10
    end

    def calculate
      connect_to_databases()

      # Find the first queued report
      report = ReportResult.where(report: Reports::SystemPerformance::Fy2015::MeasureTwo.first).where(percent_complete: 0).first
      return unless report.present? 
      Rails.logger.info "Starting report #{report.report.name}"
      report.update_attributes(percent_complete: 0.01)
      # Overview: Calculate return to homelessness after exit to permanent housing
      results = {
        two_a2: {
          title:  nil,
          value: 'Exit was from SO',
        },
        two_a3: {
          title: nil,
          value: 'Exit was from ES',
        },
        two_a4: {
          title: nil,
          value: 'Exit was from TH',
        },
        two_a5: {
          title: nil,
          value: 'Exit was from SH',
        },
        two_a6: {
          title: nil,
          value: 'Exit was from PH',
        },
        two_a7: {
          title: nil,
          value: 'Total retuns to homelessness',
        },
        two_b1: {
          title: nil,
          value: 'Total number of persons who exited to a permanent housing destination (2 Years Prior)',
        },
        two_b2: {
          title: 'Total number of persons who exited to a permanent housing destination; exit was from SO (2 years prior)',
          value: 0,
        },
        two_b3: {
          title: 'Total number of persons who exited to a permanent housing destination; exit was from ES (2 years prior)',
          value: 0,
        },
        two_b4: {
          title: 'Total number of persons who exited to a permanent housing destination; exit was from TH (2 years prior)',
          value: 0,
        },
        two_b5: {
          title: 'Total number of persons who exited to a permanent housing destination; exit was from SH (2 years prior)',
          value: 0,
        },
        two_b6: {
          title: 'Total number of persons who exited to a permanent housing destination; exit was from PH (2 years prior)',
          value: 0,
        },
        two_b7: {
          title: 'Total number of persons who exited to a permanent housing destination; Total retuns to homelessness (2 years prior)',
          value: 0,
        },
        two_c1: {
          title: nil,
          value: 'Number returing to homelessness in less than 6 months (0-180 days)',
        },
        two_c2: {
          title: 'Number returing to homelessness in less than 6 months; exit was from SO (0-180 days) ',
          value: 0,
        },
        two_c3: {
          title: 'Number returing to homelessness in less than 6 months; exit was from ES (0-180 days) ',
          value: 0,
        },
        two_c4: {
          title: 'Number returing to homelessness in less than 6 months; exit was from TH (0-180 days) ',
          value: 0,
        },
        two_c5: {
          title: 'Number returing to homelessness in less than 6 months; exit was from SH (0-180 days) ',
          value: 0,
        },
        two_c6: {
          title: 'Number returing to homelessness in less than 6 months; exit was from PH (0-180 days) ',
          value: 0,
        },
        two_c7: {
          title: 'Number returing to homelessness in less than 6 months; Total retuns to homelessness (0-180 days) ',
          value: 0,
        },
        two_d1: {
          title: nil,
          value: 'Percentage of returns in less than 6 months (0-180 days)',
        },
        two_d2: {
          title: 'Percentage of returns in less than 6 months; exit was from SO (0-180 days)',
          value: 0,
        },
        two_d3: {
          title: 'Percentage of returns in less than 6 months; exit was from ES (0-180 days)',
          value: 0,
        },
        two_d4: {
          title: 'Percentage of returns in less than 6 months; exit was from TH (0-180 days)',
          value: 0,
        },
        two_d5: {
          title: 'Percentage of returns in less than 6 months; exit was from SH (0-180 days)',
          value: 0,
        },
        two_d6: {
          title: 'Percentage of returns in less than 6 months; exit was from PH (0-180 days)',
          value: 0,
        },
        two_d7: {
          title: 'Percentage of returns in less than 6 months; Total retuns to homelessness (0-180 days)',
          value: 0,
        },
        two_e1: {
          title: nil,
          value: 'Number returning to homelessness from 6 to 12 months (181-365 days)',
        },
        two_e2: {
          title: 'Number returning to homelessness from 6 to 12 months; exit was from SO (181-365 days)',
          value: 0,
        },
        two_e3: {
          title: 'Number returning to homelessness from 6 to 12 months; exit was from ES (181-365 days)',
          value: 0,
        },
        two_e4: {
          title: 'Number returning to homelessness from 6 to 12 months; exit was from TH (181-365 days)',
          value: 0,
        },
        two_e5: {
          title: 'Number returning to homelessness from 6 to 12 months; exit was from SH (181-365 days)',
          value: 0,
        },
        two_e6: {
          title: 'Number returning to homelessness from 6 to 12 months; exit was from PH (181-365 days)',
          value: 0,
        },
        two_e7: {
          title: 'Number returning to homelessness from 6 to 12 months; Total retuns to homelessness (181-365 days)',
          value: 0,
        },
        two_f1: {
          title: nil,
          value: 'Percentage of returns from 6 to 12 months (181-365 days)',
        },
        two_f2: {
          title: 'Percentage of returns from 6 to 12 months; exit was from SO (181-365 days)',
          value: 0,
        },
        two_f3: {
          title: 'Percentage of returns from 6 to 12 months; exit was from ES (181-365 days)',
          value: 0,
        },
        two_f4: {
          title: 'Percentage of returns from 6 to 12 months; exit was from TH (181-365 days)',
          value: 0,
        },
        two_f5: {
          title: 'Percentage of returns from 6 to 12 months; exit was from SH (181-365 days)',
          value: 0,
        },
        two_f6: {
          title: 'Percentage of returns from 6 to 12 months; exit was from PH (181-365 days)',
          value: 0,
        },
        two_f7: {
          title: 'Percentage of returns from 6 to 12 months; Total retuns to homelessness (181-365 days)',
          value: 0,
        },
        two_g1: {
          title: nil,
          value: 'Number returning to homelessness from 13 to 24 months (366-730 days)',
        },
        two_g2: {
          title: 'Number returning to homelessness from 13 to 24 months; exit was from SO (366-730 days)',
          value: 0,
        },
        two_g3: {
          title: 'Number returning to homelessness from 13 to 24 months; exit was from ES (366-730 days)',
          value: 0,
        },
        two_g4: {
          title: 'Number returning to homelessness from 13 to 24 months; exit was from TH (366-730 days)',
          value: 0,
        },
        two_g5: {
          title: 'Number returning to homelessness from 13 to 24 months; exit was from SH (366-730 days)',
          value: 0,
        },
        two_g6: {
          title: 'Number returning to homelessness from 13 to 24 months; exit was from PH (366-730 days)',
          value: 0,
        },
        two_g7: {
          title: 'Number returning to homelessness from 13 to 24 months; Total retuns to homelessness (366-730 days)',
          value: 0,
        },
        two_h1: {
          title: nil,
          value: 'Percentage of returns from 13 to 24 months (366-730 days)',
        },
        two_h2: {
          title: 'Percentage of returns from 13 to 24 months; exit was from SO (366-730 days)',
          value: 0,
        },
        two_h3: {
          title: 'Percentage of returns from 13 to 24 months; exit was from ES (366-730 days)',
          value: 0,
        },
        two_h4: {
          title: 'Percentage of returns from 13 to 24 months; exit was from TH (366-730 days)',
          value: 0,
        },
        two_h5: {
          title: 'Percentage of returns from 13 to 24 months; exit was from SH (366-730 days)',
          value: 0,
        },
        two_h6: {
          title: 'Percentage of returns from 13 to 24 months; exit was from PH (366-730 days)',
          value: 0,
        },
        two_h7: {
          title: 'Percentage of returns from 13 to 24 months; Total retuns to homelessness (366-730 days)',
          value: 0,
        },
        two_i1: {
          title: nil,
          value: 'Number of returns in 2 years',
        },
        two_i2: {
          title: 'Number of returns in 2 years; exit was from SO',
          value: 0,
        },
        two_i3: {
          title: 'Number of returns in 2 years; exit was from ES',
          value: 0,
        },
        two_i4: {
          title: 'Number of returns in 2 years; exit was from TH',
          value: 0,
        },
        two_i5: {
          title: 'Number of returns in 2 years; exit was from SH',
          value: 0,
        },
        two_i6: {
          title: 'Number of returns in 2 years; exit was from PH',
          value: 0,
        },
        two_i7: {
          title: 'Number of returns in 2 years; Total retuns to homelessness',
          value: 0,
        },
        two_j1: {
          title: nil,
          value: 'Percentage of returns in 2 years',
        },
        two_j2: {
          title: 'Percentage of returns in 2 years; exit was from SO',
          value: 0,
        },
        two_j3: {
          title: 'Percentage of returns in 2 years; exit was from ES',
          value: 0,
        },
        two_j4: {
          title: 'Percentage of returns in 2 years; exit was from TH',
          value: 0,
        },
        two_j5: {
          title: 'Percentage of returns in 2 years; exit was from SH',
          value: 0,
        },
        two_j6: {
          title: 'Percentage of returns in 2 years; exit was from PH',
          value: 0,
        },
        two_j7: {
          title: 'Percentage of returns in 2 years; Total retuns to homelessness',
          value: 0,
        },
      }

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
      # 
     
      project_types = SO + ES + TH + SH + PH 
      look_back_until =  LOOKBACK_STOP_DATE.to_date >= (REPORT_START_DATE.to_date - 730.days) ? LOOKBACK_STOP_DATE : (REPORT_START_DATE.to_date - 730.days).strftime('%Y-%m-%d')
      look_forward_until = (REPORT_END_DATE.to_date - 730.days).strftime('%Y-%m-%d')

      project_exits_universe = GrdaWarehouse::ClientHousingHistory.where("record_type = 'exit'
        and last_date_in_program <= '#{look_forward_until}'
        and last_date_in_program >= '#{look_back_until}'
        and program_type in (#{project_types.compact.join(', ')})").order(unduplicated_client_id: :asc).order(last_date_in_program: :asc).select(:unduplicated_client_id, :destination, :date, :first_date_in_program, :last_date_in_program, :program_type, :program_id)
      

      project_exits_to_ph = {}
      project_exists_from = {so: [], es: [], th: [], sh: [], ph: []}
      # Loop over exits
      # If we find an exit with a destination in (3, 10, 11, 19, 20, 21, 22, 23, 26, 28)
      # log the earliest instance of each client (first exit to PH)
      project_exits_universe.each do |p_exit|
        if PERMANENT_DESTINATIONS.include? p_exit[:destination] 
          unless project_exits_to_ph[p_exit[:unduplicated_client_id]].present?
            project_exits_to_ph[p_exit[:unduplicated_client_id]] = p_exit
          end
        end
      end

      project_exits_to_ph.each do |id, p_exit|
        case p_exit[:program_type]
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

      results[:two_b2][:value] = project_exists_from[:so].size
      results[:two_b3][:value] = project_exists_from[:es].size
      results[:two_b4][:value] = project_exists_from[:th].size
      results[:two_b5][:value] = project_exists_from[:sh].size
      results[:two_b6][:value] = project_exists_from[:ph].size
      results[:two_b7][:value] = results[:two_b2][:value] + results[:two_b3][:value] + results[:two_b4][:value] + results[:two_b5][:value] + results[:two_b6][:value]

      report.update_attributes(percent_complete: 10)

      # Find anyone who has returned to homelessness after 14+ days
      # Find their first return to homelessness and calculate the days between the 
      # time they exited to PH and returned to homelessness
      # Note: if the next entry is to a TH, the entry must be 14 days after the original
      # exit to count
      # Note: if the next entry is to a PH, it is only counted if it occurs more than 14 
      # days after the original exit, or more than 14 days after a PH
      project_exit_counts = {
        c_0_180_days: {so: [], es: [], th: [], sh: [], ph: []},
        e_181_365_days: {so: [], es: [], th: [], sh: [], ph: []}, 
        g_366_730_days: {so: [], es: [], th: [], sh: [], ph: []}
      }
      project_exits_to_ph.each do |id, p_exit|

        client_entries_all = GrdaWarehouse::ClientHousingHistory.where("record_type = 'entry'
          and first_date_in_program <= '#{REPORT_END_DATE}'
          and first_date_in_program > '#{p_exit[:last_date_in_program].strftime('%Y-%m-%d')}'
          and unduplicated_client_id = #{p_exit[:unduplicated_client_id]}").order(date: :asc).select(:unduplicated_client_id, :destination, :date, :first_date_in_program, :last_date_in_program, :program_type, :program_id)
        
        # Build a useful universe of entries
        # Make note of project type each day, PH will take priority over TH which is > else
        client_entries = {}
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
          # If the next destination is PH, it must be > 14 days since exit to count
          elsif program_types.include?('PH')
            #puts "#{p_exit[:unduplicated_client_id]}: #{day.to_date} ---- #{ph_check_date.to_date} #{(day.to_date - ph_check_date.to_date).to_i}"
            if (day.to_date - ph_check_date.to_date).to_i < 14
              next_end_date = GrdaWarehouse::ClientHousingHistory.where("record_type = 'entry'
                and first_date_in_program = '#{day.strftime("%Y-%m-%d")}'
                and unduplicated_client_id = #{p_exit[:unduplicated_client_id]}
                and program_type in (#{PH.join(',')})
                ").order(last_date_in_program: :desc).limit(1).pluck(:last_date_in_program).first
              if next_end_date.nil?
                break
              end
              ph_check_date = next_end_date
            else
              case (day.to_date - p_exit[:last_date_in_program].to_date).to_i
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
      results[:two_c2][:value] = project_exit_counts[:c_0_180_days][:so].size
      results[:two_c3][:value] = project_exit_counts[:c_0_180_days][:es].size
      results[:two_c4][:value] = project_exit_counts[:c_0_180_days][:th].size
      results[:two_c5][:value] = project_exit_counts[:c_0_180_days][:sh].size
      results[:two_c6][:value] = project_exit_counts[:c_0_180_days][:ph].size
      results[:two_e2][:value] = project_exit_counts[:e_181_365_days][:so].size
      results[:two_e3][:value] = project_exit_counts[:e_181_365_days][:es].size
      results[:two_e4][:value] = project_exit_counts[:e_181_365_days][:th].size
      results[:two_e5][:value] = project_exit_counts[:e_181_365_days][:sh].size
      results[:two_e6][:value] = project_exit_counts[:e_181_365_days][:ph].size
      results[:two_g2][:value] = project_exit_counts[:g_366_730_days][:so].size
      results[:two_g3][:value] = project_exit_counts[:g_366_730_days][:es].size
      results[:two_g4][:value] = project_exit_counts[:g_366_730_days][:th].size
      results[:two_g5][:value] = project_exit_counts[:g_366_730_days][:sh].size
      results[:two_g6][:value] = project_exit_counts[:g_366_730_days][:ph].size

      # simple math
      results[:two_c7][:value] = results[:two_c2][:value] + results[:two_c3][:value] + results[:two_c4][:value] + results[:two_c5][:value] + results[:two_c6][:value]
      results[:two_e7][:value] = results[:two_e2][:value] + results[:two_e3][:value] + results[:two_e4][:value] + results[:two_e5][:value] + results[:two_e6][:value]
      results[:two_g7][:value] = results[:two_g2][:value] + results[:two_g3][:value] + results[:two_g4][:value] + results[:two_g5][:value] + results[:two_g6][:value]
      
      results[:two_d2][:value] = ((results[:two_c2][:value].to_f / results[:two_b2][:value]) * 100).round(2)
      results[:two_d3][:value] = ((results[:two_c3][:value].to_f / results[:two_b3][:value]) * 100).round(2)
      results[:two_d4][:value] = ((results[:two_c4][:value].to_f / results[:two_b4][:value]) * 100).round(2)
      results[:two_d5][:value] = ((results[:two_c5][:value].to_f / results[:two_b5][:value]) * 100).round(2)
      results[:two_d6][:value] = ((results[:two_c6][:value].to_f / results[:two_b6][:value]) * 100).round(2)
      results[:two_d7][:value] = ((results[:two_c7][:value].to_f / results[:two_b7][:value]) * 100).round(2)

      results[:two_f2][:value] = ((results[:two_e2][:value].to_f / results[:two_b2][:value]) * 100).round(2)
      results[:two_f3][:value] = ((results[:two_e3][:value].to_f / results[:two_b3][:value]) * 100).round(2)
      results[:two_f4][:value] = ((results[:two_e4][:value].to_f / results[:two_b4][:value]) * 100).round(2)
      results[:two_f5][:value] = ((results[:two_e5][:value].to_f / results[:two_b5][:value]) * 100).round(2)
      results[:two_f6][:value] = ((results[:two_e6][:value].to_f / results[:two_b6][:value]) * 100).round(2)
      results[:two_f7][:value] = ((results[:two_e7][:value].to_f / results[:two_b7][:value]) * 100).round(2)

      results[:two_h2][:value] = ((results[:two_g2][:value].to_f / results[:two_b2][:value]) * 100).round(2)
      results[:two_h3][:value] = ((results[:two_g3][:value].to_f / results[:two_b3][:value]) * 100).round(2)
      results[:two_h4][:value] = ((results[:two_g4][:value].to_f / results[:two_b4][:value]) * 100).round(2)
      results[:two_h5][:value] = ((results[:two_g5][:value].to_f / results[:two_b5][:value]) * 100).round(2)
      results[:two_h6][:value] = ((results[:two_g6][:value].to_f / results[:two_b6][:value]) * 100).round(2)
      results[:two_h7][:value] = ((results[:two_g7][:value].to_f / results[:two_b7][:value]) * 100).round(2)

      results[:two_i2][:value] = results[:two_c2][:value] + results[:two_e2][:value] + results[:two_g2][:value]
      results[:two_i3][:value] = results[:two_c3][:value] + results[:two_e3][:value] + results[:two_g2][:value]
      results[:two_i4][:value] = results[:two_c4][:value] + results[:two_e4][:value] + results[:two_g4][:value]
      results[:two_i5][:value] = results[:two_c5][:value] + results[:two_e5][:value] + results[:two_g5][:value]
      results[:two_i6][:value] = results[:two_c6][:value] + results[:two_e6][:value] + results[:two_g6][:value]
      results[:two_i7][:value] = results[:two_c7][:value] + results[:two_e7][:value] + results[:two_g7][:value]

      results[:two_j2][:value] = ((results[:two_i2][:value].to_f / results[:two_b2][:value]) * 100).round(2)
      results[:two_j3][:value] = ((results[:two_i3][:value].to_f / results[:two_b3][:value]) * 100).round(2)
      results[:two_j4][:value] = ((results[:two_i4][:value].to_f / results[:two_b4][:value]) * 100).round(2)
      results[:two_j5][:value] = ((results[:two_i5][:value].to_f / results[:two_b5][:value]) * 100).round(2)
      results[:two_j6][:value] = ((results[:two_i6][:value].to_f / results[:two_b6][:value]) * 100).round(2)
      results[:two_j7][:value] = ((results[:two_i7][:value].to_f / results[:two_b7][:value]) * 100).round(2)

      
      Rails.logger.info results.inspect
      # save our progress
      report.update_attributes(percent_complete: 100, results: results, completed_at: Time.now)
    end
  end
end
