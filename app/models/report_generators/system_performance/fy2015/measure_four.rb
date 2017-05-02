module ReportGenerators::SystemPerformance::Fy2015
  class MeasureFour
    REPORT_START_DATE = '2014-10-01'
    REPORT_END_DATE = '2015-09-30'
    LOOKBACK_STOP_DATE = '2012-10-01'

    PH = [3,9,10,13]
    TH = [2]
    ES = [1] 
    SH = [8]

    DC_IDS = [139]

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

   # private
   def connect_to_databases
      config = Rails.configuration.database_configuration["#{Rails.env}_old_warehouse".parameterize.underscore]
      grda_warehouse_config = Rails.configuration.database_configuration["#{Rails.env}_grda_warehouse".parameterize.underscore]

      @c0 = TinyTds::Client.new username: config['username'], password: config['password'], host: config['host'], port: config['port'], database: config['database'], timeout: 20
      @c_grda_warehouse = TinyTds::Client.new username: grda_warehouse_config['username'], password: grda_warehouse_config['password'], host: grda_warehouse_config['host'], port: grda_warehouse_config['port'], database: grda_warehouse_config['database'], timeout: 300
    end

    def calculate
      connect_to_databases()
      # TODO: Because we don't push head of household Housing Status onto dependents, we may need to lookup Housing Status if we aren't the head of household
      
      # Find the first queued report
      report = ReportResult.where(report: Reports::SystemPerformance::Fy2015::MeasureFour.first).where(percent_complete: 0).first
      return unless report.present?

      Rails.logger.info "Starting report #{report.report.name}"
      report.update_attributes(percent_complete: 0.01)
      results = {
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
      # To get the appropriate Federal Partner Funding Sources (2.6) we need to look at the agency info table provided by Jennifer Flynn from DND
      # Specifically we need 2,3,4,5 which correlate to:
      # FederalPartnerProgram = 'HUD CoC' and Component in ('PSH', 'RRH', 'SSO', 'TH')
      
      # sql = "
      #   select programid, databaseid
      #   from hud_performance_agency_program_info
      #   where CoCFunded = 1 
      #     and Component in ('PSH', 'RRH', 'SSO', 'TH')
      #     and GrantStartDate <= '#{REPORT_END_DATE}'
      #     and (GrantEndDate is null or GrantEndDate >= '#{REPORT_START_DATE}')
      #     and ProgramTypeCode in (#{(PH + SH + TH).join(', ')})
      # "
      # Find anyone 18 years or older in a relevant project,
      # get their latest project entry date within the report range for which the length of stay is >= 365 days. 
      universe_of_stayers = calculate_stayers
      report.update_attributes(percent_complete: 10)
      # Per Jennifer Flynn, ignore 60 day window around program start anniversary, 
      # that was not the instructions given to programs about when to collect assessments
      universe_of_stayers = add_stayer_income(universe_of_stayers)
      report.update_attributes(percent_complete: 40)
      results[:four1_c2][:value] = universe_of_stayers.size
      results[:four2_c2][:value] = universe_of_stayers.size
      results[:four3_c2][:value] = universe_of_stayers.size
      universe_of_stayers.each do |client|
        if client['latest_earned_income'] - client['earliest_earned_income'] > 0
          results[:four1_c3][:value] += 1
        end
        if client['latest_non_earned_income'] - client['earliest_non_earned_income'] > 0
          results[:four2_c3][:value] += 1
        end
        if (client['latest_earned_income'] + client['latest_non_earned_income']) - (client['earliest_earned_income'] + client['earliest_non_earned_income']) > 0
          results[:four3_c3][:value] += 1
        end
      end

      universe_of_leavers = calculate_leavers 
      report.update_attributes(percent_complete: 50)
      universe_of_leavers = add_leaver_income(universe_of_leavers)
      report.update_attributes(percent_complete: 90)
      results[:four4_c2][:value] = universe_of_leavers.size
      results[:four5_c2][:value] = universe_of_leavers.size
      results[:four6_c2][:value] = universe_of_leavers.size
      universe_of_leavers.each do |client|
        if client['latest_earned_income'] - client['earliest_earned_income'] > 0
          results[:four4_c3][:value] += 1
        end
        if client['latest_non_earned_income'] - client['earliest_non_earned_income'] > 0
          results[:four5_c3][:value] += 1
        end
        if (client['latest_earned_income'] + client['latest_non_earned_income']) - (client['earliest_earned_income'] + client['earliest_non_earned_income']) > 0
          results[:four6_c3][:value] += 1
        end
      end

      Rails.logger.info results.inspect
      # save our progress
      report.update_attributes(percent_complete: 100, results: results, completed_at: Time.now)
    end

    def calculate_stayers
      sql = "
        select distinct #{GrdaWarehouse::UnduplicatedClient.table_name}.unduplicated_client_id, client_unique_id, first_date_in_program, last_date_in_program, program_id, database_id, age
        from #{GrdaWarehouse::ClientHousingHistory.table_name}, hud_performance_agency_program_info, #{GrdaWarehouse::UnduplicatedClient.table_name}
        where #{GrdaWarehouse::ClientHousingHistory.table_name}.program_id = hud_performance_agency_program_info.programid
          and #{GrdaWarehouse::ClientHousingHistory.table_name}.database_id = hud_performance_agency_program_info.databaseid
          and #{GrdaWarehouse::ClientHousingHistory.table_name}.unduplicated_client_id = #{GrdaWarehouse::UnduplicatedClient.table_name}.unduplicated_client_id
          and CoCFunded = 1 
          and Component in ('PSH', 'RRH', 'SSO', 'TH')
          and GrantStartDate <= '#{REPORT_END_DATE}'
          and (GrantEndDate is null or GrantEndDate >= '#{REPORT_START_DATE}')
          and ProgramTypeCode in (#{(PH + SH + TH).join(', ')})
          and #{GrdaWarehouse::ClientHousingHistory.table_name}.age >= 18
          and first_date_in_program <= '#{REPORT_END_DATE}'
          and (last_date_in_program is null or last_date_in_program > '#{REPORT_END_DATE}')
          and record_type = 'entry'
        order by unduplicated_client_id asc, first_date_in_program asc
      "
      results = @c_grda_warehouse.execute(sql).each
      # remove any stays less than 365 days long
      # keep only the most recent stay per client 
      participants = results.
        select{ |row| (row['last_date_in_program'].nil? && (REPORT_END_DATE.to_date - row['first_date_in_program'].to_date) >= 365) || row['last_date_in_program'].present? && (row['last_date_in_program'].to_date - row['first_date_in_program'].to_date) >= 365}.
        group_by{ |row| row['unduplicated_client_id']}
        .map{|k,v| v.last}
    end

    def calculate_leavers
      sql = "
        select distinct #{GrdaWarehouse::UnduplicatedClient.table_name}.unduplicated_client_id, client_unique_id, first_date_in_program, last_date_in_program, program_id, database_id, age
        from #{GrdaWarehouse::ClientHousingHistory.table_name}, hud_performance_agency_program_info, #{GrdaWarehouse::UnduplicatedClient.table_name}
        where #{GrdaWarehouse::ClientHousingHistory.table_name}.program_id = hud_performance_agency_program_info.programid
          and #{GrdaWarehouse::ClientHousingHistory.table_name}.database_id = hud_performance_agency_program_info.databaseid
          and #{GrdaWarehouse::ClientHousingHistory.table_name}.unduplicated_client_id = #{GrdaWarehouse::UnduplicatedClient.table_name}.unduplicated_client_id
          and CoCFunded = 1 
          and Component in ('PSH', 'RRH', 'SSO', 'TH')
          and GrantStartDate <= '#{REPORT_END_DATE}'
          and (GrantEndDate is null or GrantEndDate >= '#{REPORT_START_DATE}')
          and ProgramTypeCode in (#{(PH + SH + TH).join(', ')})
          and #{GrdaWarehouse::ClientHousingHistory.table_name}.age >= 18
          and last_date_in_program >= '#{REPORT_START_DATE}'
          and last_date_in_program <= '#{REPORT_END_DATE}'
          and record_type = 'entry'
        order by unduplicated_client_id asc, first_date_in_program asc
      "
      results = @c_grda_warehouse.execute(sql).each
      # remove any stays less than 365 days long
      # keep only the most recent stay per client 
      participants = results.
        group_by{ |row| row['unduplicated_client_id']}
        .map{|k,v| v.last}
    end

    def add_stayer_income universe_of_stayers
      # add columns to each row for the following: 
      # latest_earned_income -- SourceCode = 1 & IncomeBenefitType = 1
      # latest_non_earned_income -- IncomeBenefitType = 2 || IncomeBenefitType = 1 && SourceCode <> 1
      # earliest_earned_income -- SourceCode = 1 & IncomeBenefitType = 1
      # earliest_non_earned_income -- IncomeBenefitType = 2 || IncomeBenefitType = 1 && SourceCode <> 1
       
      universe_of_stayers.each_with_index do |row, index|
        sql = "
          select DataCollectionDate, DataCollectionType, IncomeBenefitType, SourceCode, MonthlyAmount
          from DC_ProgramParticipation, DC_IncomeBenefit
          where DC_ProgramParticipation.ClientUniqueID = '#{row['client_unique_id']}'
            and DC_ProgramParticipation.ClientCode = DC_IncomeBenefit.ClientCode
            and DC_ProgramParticipation.ProgramID = DC_IncomeBenefit.ProgramID
            and DC_ProgramParticipation.DatabaseID = DC_IncomeBenefit.DatabaseID
            and DC_ProgramParticipation.dc_id = DC_IncomeBenefit.dc_id
            and DC_ProgramParticipation.ProgramID = #{row['program_id']}
            and DC_ProgramParticipation.DatabaseID = '#{row['database_id']}'
            and DC_IncomeBenefit.DataCollectionDate <= '#{REPORT_END_DATE}'
            and DC_IncomeBenefit.DC_ID in (#{DC_IDS.join(', ')})
          order by DC_IncomeBenefit.DataCollectionDate asc
        "
        results = @c0.execute(sql).each
        assessment_types = results.group_by{|m| m["DataCollectionType"]}
        income_map = {} # make a useful group of income data {1 => date => [rows], 5 => date => [rows]}
        assessment_types.each do |k, v|
          income_map[k] = v.group_by{|m| m["DataCollectionDate"]}
        end
        # Grab the last day from the 5 (annual assessment) group
        if income_map['5'].present?
          latest_group = income_map['5'].values.last
        end
        # If we have more than one 5, use the first as the earliest, otherwise if we have a 1 group use that, if not, we won't calculate
        if income_map['5'].present? && income_map['5'].size > 1
          earliest_group = income_map['5'].values[-2]
        elsif income_map['1'].present?
          earliest_group = income_map['1'].values.first
        end
        # TODO: MonthlyAmount should never be reported as < 0, so far, there aren't any in the database that are negative
        # but we should check here and count those as 0
        if latest_group.present?
          universe_of_stayers[index]['latest_earned_income'] = 0
          universe_of_stayers[index]['latest_non_earned_income'] = 0
          latest_group.each do |x|
            if x['SourceCode'] == 1 && x['IncomeBenefitType'] == 1
              universe_of_stayers[index]['latest_earned_income'] += x['MonthlyAmount'].to_i
            else
              universe_of_stayers[index]['latest_non_earned_income'] += x['MonthlyAmount'].to_i
            end
          end
        end
        if earliest_group.present?
          universe_of_stayers[index]['earliest_earned_income'] = 0
          universe_of_stayers[index]['earliest_non_earned_income'] = 0
          earliest_group.each do |x|
            if x['SourceCode'] == 1 && x['IncomeBenefitType'] == 1
              universe_of_stayers[index]['earliest_earned_income'] += x['MonthlyAmount'].to_i
            else
              universe_of_stayers[index]['earliest_non_earned_income'] += x['MonthlyAmount'].to_i
            end
          end
        end
      end
      universe_of_stayers.select{|m| m["latest_earned_income"].present? && m["earliest_earned_income"].present?}
    end


    def add_leaver_income universe_of_leavers
      # add columns to each row for the following: 
      # latest_earned_income -- SourceCode = 1 & IncomeBenefitType = 1
      # latest_non_earned_income -- IncomeBenefitType = 2 || IncomeBenefitType = 1 && SourceCode <> 1
      # earliest_earned_income -- SourceCode = 1 & IncomeBenefitType = 1
      # earliest_non_earned_income -- IncomeBenefitType = 2 || IncomeBenefitType = 1 && SourceCode <> 1
       
      universe_of_leavers.each_with_index do |row, index|
        sql = "
          select DataCollectionDate, DataCollectionType, IncomeBenefitType, SourceCode, MonthlyAmount
          from DC_ProgramParticipation, DC_IncomeBenefit
          where DC_ProgramParticipation.ClientUniqueID = '#{row['client_unique_id']}'
            and DC_ProgramParticipation.ClientCode = DC_IncomeBenefit.ClientCode
            and DC_ProgramParticipation.ProgramID = DC_IncomeBenefit.ProgramID
            and DC_ProgramParticipation.DatabaseID = DC_IncomeBenefit.DatabaseID
            and DC_ProgramParticipation.dc_id = DC_IncomeBenefit.dc_id
            and DC_ProgramParticipation.ProgramID = #{row['program_id']}
            and DC_ProgramParticipation.DatabaseID = '#{row['database_id']}'
            and DC_IncomeBenefit.DataCollectionDate <= '#{REPORT_END_DATE}'
            and DC_IncomeBenefit.DC_ID in (#{DC_IDS.join(', ')})
          order by DC_IncomeBenefit.DataCollectionDate asc
        "
        results = @c0.execute(sql).each
        assessment_types = results.group_by{|m| m["DataCollectionType"]}
        income_map = {} # make a useful group of income data {1 => date => [rows], 3 => date => [rows]}
        assessment_types.each do |k, v|
          income_map[k] = v.group_by{|m| m["DataCollectionDate"]}
        end
        # Grab the last day from the 3 (exit assessment) group
        if income_map['3'].present?
          latest_group = income_map['3'].values.last
        end
        if income_map['1'].present?
          earliest_group = income_map['1'].values.first
        end
        # TODO: MonthlyAmount should never be reported as < 0, so far, there aren't any in the database that are negative
        # but we should check here and count those as 0
        if latest_group.present?
          universe_of_leavers[index]['latest_earned_income'] = 0
          universe_of_leavers[index]['latest_non_earned_income'] = 0
          latest_group.each do |x|
            if x['SourceCode'] == 1 && x['IncomeBenefitType'] == 1
              universe_of_leavers[index]['latest_earned_income'] += x['MonthlyAmount'].to_i
            else
              universe_of_leavers[index]['latest_non_earned_income'] += x['MonthlyAmount'].to_i
            end
          end
        end
        if earliest_group.present?
          universe_of_leavers[index]['earliest_earned_income'] = 0
          universe_of_leavers[index]['earliest_non_earned_income'] = 0
          earliest_group.each do |x|
            if x['SourceCode'] == 1 && x['IncomeBenefitType'] == 1
              universe_of_leavers[index]['earliest_earned_income'] += x['MonthlyAmount'].to_i
            else
              universe_of_leavers[index]['earliest_non_earned_income'] += x['MonthlyAmount'].to_i
            end
          end
        end
      end
      universe_of_leavers.select{|m| m["latest_earned_income"].present? && m["earliest_earned_income"].present?}
    end
  end
end
