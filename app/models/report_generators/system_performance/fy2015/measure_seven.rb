module ReportGenerators::SystemPerformance::Fy2015
  class MeasureSeven
    REPORT_START_DATE = '2014-10-01'
    REPORT_END_DATE = '2015-09-30'
    LOOKBACK_STOP_DATE = '2012-10-01'

    PH = [3,9,10,13] 
    TH = [2]
    ES = [1] 
    SH = [8]
    SO = 4
    RRH = [13]
    PH_PSH = [3,9,10] # All PH except 13, Measure 7 doesn't count RRH

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
      connect_to_databases()
      # Find the first queued report
      report = ReportResult.where(report: Reports::SystemPerformance::Fy2015::MeasureSeven.first).where(percent_complete: 0).first
      return unless report.present?

      Rails.logger.info "Starting report #{report.report.name}"
      report.update_attributes(percent_complete: 0.01)
      # Overview: 
      # 7a.1 Success of placement from Street Outreach (SO) at finding permanent housing
      # 7b.1 Success of placement from ES, SH, TH and PH-Rapid-Re-Housing at finding permanent housing
      # 7b.2 Success of PH (except Rapid Re-Housing) at finding permanent housing
      results = {
        sevena1_a2: {
          title: nil,
          value: 'Universe: Persons who exit Street Outreach',
        },
        sevena1_a3: {
          title: nil,
          value: 'Of persons above, those who exited to temporary & some institutional destinations',
        },
        sevena1_a4: {
          title: nil,
          value: 'Of the persons above, those who exited to permanent housing destinations',
        },
        sevena1_a5: {
          title: nil,
          value: '% Successful exits',
        },
        sevena1_b1: {
          title: nil,
          value: 'Previous FY',
        },
        sevena1_b2: {
          title: 'Universe: Persons who exit Street Outreach (previous FY)',
          value: nil,
        },
        sevena1_b3: {
          title: 'Of persons above, those who exited to temporary & some institutional destinations (previous FY)',
          value: nil,
        },
        sevena1_b4: {
          title: 'Of the persons above, those who exited to permanent housing destinations (previous FY)',
          value: nil,
        },
        sevena1_b5: {
          title: '% Successful exits (previous FY)',
          value: nil,
        },
        sevena1_c1: {
          title: nil,
          value: 'Current FY',
        },
        sevena1_c2: {
          title: 'Universe: Persons who exit Street Outreach (current FY)',
          value: 0,
        },
        sevena1_c3: {
          title: 'Of persons above, those who exited to temporary & some institutional destinations (current FY)',
          value: 0,
        },
        sevena1_c4: {
          title: 'Of the persons above, those who exited to permanent housing destinations (current FY)',
          value: 0,
        },
        sevena1_c5: {
          title: '% Successful exits (current FY)',
          value: 0,
        },
        sevena1_d1: {
          title: nil,
          value: '% Difference',
        },
        sevena1_d2: {
          title: 'Universe: Persons who exit Street Outreach (% difference)',
          value: nil,
        },
        sevena1_d3: {
          title: 'Of persons above, those who exited to temporary & some institutional destinations (% difference)',
          value: nil,
        },
        sevena1_d4: {
          title: 'Of the persons above, those who exited to permanent housing destinations (% difference)',
          value: nil,
        },
        sevena1_d5: {
          title: '% Successful exits (% difference)',
          value: nil,
        },
        sevenb1_a2: {
          title: nil,
          value: 'Universe: Persons in ES, SH, TH and PH-RRH who exited',
        },
        sevenb1_a3: {
          title: nil,
          value: 'Of the persons above, those who exited to permanent housing destinations',
        },
        sevenb1_a4: {
          title: nil,
          value: '% Successful exits',
        },
        sevenb1_b1: {
          title: nil,
          value: 'Previous FY',
        },
        sevenb1_b2: {
          title: 'Universe: Persons in ES, SH, TH and PH-RRH who exited (previous FY)',
          value: nil,
        },
        sevenb1_b3: {
          title: 'Of the persons above, those who exited to permanent housing destinations (previous FY)',
          value: nil,
        },
        sevenb1_b4: {
          title: '% Successful exits (previous FY)',
          value: nil,
        },
        sevenb1_c1: {
          title: nil,
          value: 'Current FY',
        },
        sevenb1_c2: {
          title: 'Universe: Persons in ES, SH, TH and PH-RRH who exited (current FY)',
          value: 0,
        },
        sevenb1_c3: {
          title: 'Of the persons above, those who exited to permanent housing destinations (current FY)',
          value: 0,
        },
        sevenb1_c4: {
          title: '% Successful exits (current FY)',
          value: 0,
        },
        sevenb1_d1: {
          title: nil,
          value: '% Difference',
        },
        sevenb1_d2: {
          title: 'Universe: Persons in ES, SH, TH and PH-RRH who exited (% difference)',
          value: nil,
        },
        sevenb1_d3: {
          title: 'Of the persons above, those who exited to permanent housing destinations (% difference)',
          value: nil,
        },
        sevenb1_d4: {
          title: '% Successful exits (% difference)',
          value: nil,
        },
        sevenb2_a2: {
          title: nil,
          value: 'Universe: Persons in all PH projects except PH-RRH',
        },
        sevenb2_a3: {
          title: nil,
          value: 'Of the persons above, those who remained in applicable PH projects and those who exited to permanent housing destinations',
        },
        sevenb2_a4: {
          title: nil,
          value: '% Successful exits/retentions',
        },
        sevenb2_b1: {
          title: nil,
          value: 'Previous FY',
        },
        sevenb2_b2: {
          title: 'Universe: Persons in all PH projects except PH-RRH (previous FY)',
          value: nil,
        },
        sevenb2_b3: {
          title: 'Of the persons above, those who remained in applicable PH projects and those who exited to permanent housing destinations (previous FY)',
          value: nil,
        },
        sevenb2_b4: {
          title: '% Successful exits/retentions (previous FY)',
          value: nil,
        },
        sevenb2_c1: {
          title: nil,
          value: 'Current FY',
        },
        sevenb2_c2: {
          title: 'Universe: Persons in all PH projects except PH-RRH (current FY)',
          value: 0,
        },
        sevenb2_c3: {
          title: 'Of the persons above, those who remained in applicable PH projects and those who exited to permanent housing destinations (current FY)',
          value: 0,
        },
        sevenb2_c4: {
          title: '% Successful exits/retentions (current FY)',
          value: 0,
        },
        sevenb2_d1: {
          title: nil,
          value: '% Difference',
        },
        sevenb2_d2: {
          title: 'Universe: Persons in all PH projects except PH-RRH (% difference)',
          value: nil,
        },
        sevenb2_d3: {
          title: 'Of the persons above, those who remained in applicable PH projects and those who exited to permanent housing destinations (% difference)',
          value: nil,
        },
        sevenb2_d4: {
          title: '% Successful exits/retentions (% difference)',
          value: nil,
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
      
      results.merge!(calculate_7a_1())
      report.update_attributes(percent_complete: 33)
      results.merge!(calculate_7b_1())
      report.update_attributes(percent_complete: 66)
      results.merge!(calculate_7b_2())
      Rails.logger.info results
      # save our progress
      report.update_attributes(percent_complete: 100, results: results, completed_at: Time.now)
      
    end

    def calculate_7a_1
      results = {
        sevena1_c2: {
          title: 'Universe: Persons who exit Street Outreach (current FY)',
          value: 0,
        },
        sevena1_c3: {
          title: 'Of persons above, those who exited to temporary & some institutional destinations (current FY)',
          value: 0,
        },
        sevena1_c4: {
          title: 'Of the persons above, those who exited to permanent housing destinations (current FY)',
          value: 0,
        },
        sevena1_c5: {
          title: '% Successful exits (current FY)',
          value: 0,
        },
      }
      # Select clients who have a recorded stay in an SO during the report period
      # who also don't have a "bed-night" at an SO on the final day of the report 
      # eg. Those who were counted by SO, but exited to somewhere else
      sql = "
        select distinct unduplicated_client_id
        from #{GrdaWarehouse::ClientHousingHistory.table_name}
        where program_type = #{SO}
          and record_type = 'exit'
          and [date] >= '#{REPORT_START_DATE}'
          and [date] <= '#{REPORT_END_DATE}'
          and unduplicated_client_id not in (
            select distinct unduplicated_client_id
            from #{GrdaWarehouse::ClientHousingHistory.table_name}
            where program_type = #{SO}
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
            and program_type = #{SO}
            and record_type = 'exit'
            and [date] >= '#{REPORT_START_DATE}'
            and [date] <= '#{REPORT_END_DATE}'
          order by [date] desc
        "
        destinations[id] = @c_grda_warehouse_1.execute(sql).each.first["destination"]
      end
      remaining_leavers = destinations.reject{ |k,v| [6, 29, 24].include?(v.to_i)}
      results[:sevena1_c2][:value] = remaining_leavers.size
      temporary_leavers = destinations.select{ |k,v| [1, 15, 14, 27, 4, 12, 13, 5, 2, 25].include?(v.to_i)}
      results[:sevena1_c3][:value] = temporary_leavers.size
      permanent_leavers = destinations.select{ |k,v| [26, 11, 21, 3, 10, 28, 20, 19, 22, 23].include?(v.to_i)}
      results[:sevena1_c4][:value] = permanent_leavers.size
      results[:sevena1_c5][:value] = (((results[:sevena1_c3][:value].to_f + results[:sevena1_c4][:value].to_f) / results[:sevena1_c2][:value]) * 100).round(2)

      return results
    end

    def calculate_7b_1
      results = {
        sevenb1_c2: {
          title: 'Universe: Persons in ES, SH, TH and PH-RRH who exited (current FY)',
          value: 0,
        },
        sevenb1_c3: {
          title: 'Of the persons above, those who exited to permanent housing destinations (current FY)',
          value: 0,
        },
        sevenb1_c4: {
          title: '% Successful exits (current FY)',
          value: 0,
        },
      }
      # Select clients who have a recorded stay in ES, SH, TH and PH-RRH during the report period
      # who also don't have a "bed-night" at an ES, SH, TH and PH-RRH on the final day of the report 
      # eg. Those who were counted by ES, SH, TH and PH-RRH, but exited to somewhere else
      sql = "
        select distinct unduplicated_client_id
        from #{GrdaWarehouse::ClientHousingHistory.table_name}
        where program_type in (#{(SH + TH + RRH).compact.join(', ')})
          and record_type = 'exit'
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
      results[:sevenb1_c2][:value] = remaining_leavers.size
      permanent_leavers = destinations.select{ |k,v| [26, 11, 21, 3, 10, 28, 20, 19, 22, 23].include?(v.to_i)}
      results[:sevenb1_c3][:value] = permanent_leavers.size
      results[:sevenb1_c4][:value] = ((results[:sevenb1_c3][:value].to_f / results[:sevenb1_c2][:value]) * 100).round(2)
      return results
    end

    def calculate_7b_2
      results = {
        sevenb2_c2: {
          title: 'Universe: Persons in all PH projects except PH-RRH (current FY)',
          value: 0,
        },
        sevenb2_c3: {
          title: 'Of the persons above, those who remained in applicable PH projects and those who exited to permanent housing destinations (current FY)',
          value: 0,
        },
        sevenb2_c4: {
          title: '% Successful exits/retentions (current FY)',
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
          )
      "
      stayers = @c_grda_warehouse.execute(sql).each.map{|m| m["unduplicated_client_id"]} - leavers
      destinations = {}
      leavers.each do |id| 
        sql = "
          select top 1 destination
          from #{GrdaWarehouse::ClientHousingHistory.table_name}
          where  unduplicated_client_id = #{id}
            and program_type in (#{(PH_PSH).compact.join(', ')})
            and record_type = 'exit'
            and [date] >= '#{REPORT_START_DATE}'
            and [date] <= '#{REPORT_END_DATE}'
          order by [date] desc
        "
        destinations[id] = @c_grda_warehouse_1.execute(sql).each.first["destination"]
      end
      remaining_leavers = destinations.reject{ |k,v| [15, 6, 25, 24].include?(v.to_i)}
      results[:sevenb2_c2][:value] = remaining_leavers.size + stayers.size
      permanent_leavers = destinations.select{ |k,v| [26, 11, 21, 3, 10, 28, 20, 19, 22, 23].include?(v.to_i)}
      results[:sevenb2_c3][:value] = permanent_leavers.size + stayers.size
      results[:sevenb2_c4][:value] = ((results[:sevenb2_c3][:value].to_f / results[:sevenb2_c2][:value]) * 100).round(2)
      return results
    end
  end
end
