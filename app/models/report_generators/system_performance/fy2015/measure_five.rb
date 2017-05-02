module ReportGenerators::SystemPerformance::Fy2015
  class MeasureFive
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
   def connect_to_databases
      grda_warehouse_config = Rails.configuration.database_configuration["#{Rails.env}_grda_warehouse".parameterize.underscore]

      @c_grda_warehouse = TinyTds::Client.new username: grda_warehouse_config['username'], password: grda_warehouse_config['password'], host: grda_warehouse_config['host'], port: grda_warehouse_config['port'], database: grda_warehouse_config['database'], timeout: 300
    end

    def calculate
      connect_to_databases()
      
      # Find the first queued report
      report = ReportResult.where(report: Reports::SystemPerformance::Fy2015::MeasureFive.first).where(percent_complete: 0).first
      return unless report.present? 
      Rails.logger.info "Starting report #{report.report.name}"
      report.update_attributes(percent_complete: 0.01)
      # Overview: Determine the number of clients in the system in specific programs during the
      # report period.  Of those, were any active in the two years prior?
      results = {
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
      
      # 5.1 
      # Select clients entering any of the applicable project types in the report date range.
      relevent_project_types = ES + SH + TH
      clients = get_universe(relevent_project_types)
      results[:five1_c2][:value] = clients.size
      # save our progress
      report.update_attributes(percent_complete: 1)
      # Determine the client's first start date within the date range
      previous_clients = find_first_entries(clients, relevent_project_types)
      results[:five1_c3][:value] = previous_clients.size
      results[:five1_c4][:value] = results[:five1_c2][:value] - results[:five1_c3][:value]
      # save our progress
      report.update_attributes(percent_complete: 50)
      # 5.2 
      # Select clients entering any of the applicable project types in the report date range.
      relevent_project_types = ES + SH + TH + PH
      clients = get_universe(relevent_project_types)
      # save our progress
      report.update_attributes(percent_complete: 51)
      results[:five2_c2][:value] = clients.size
      # Determine the client's first start date within the date range
      previous_clients = find_first_entries(clients, relevent_project_types)
      results[:five2_c3][:value] = previous_clients.size
      results[:five2_c4][:value] = results[:five2_c2][:value] - results[:five2_c3][:value]
      Rails.logger.info results.inspect
      # save our progress
      report.update_attributes(percent_complete: 100, results: results, completed_at: Time.now)
      

    end
    private
    def get_universe relevent_project_types
      sql = "
          select distinct unduplicated_client_id
          from #{GrdaWarehouse::ClientHousingHistory.table_name}
          where record_type = 'entry'
            and program_type in (#{relevent_project_types.compact.join(', ')})
            and first_date_in_program >= '#{REPORT_START_DATE}'
            and first_date_in_program <= '#{REPORT_END_DATE}'
        "
        clients = {}
        result = @c_grda_warehouse.execute(sql)
        result.each do |row|
          clients[row['unduplicated_client_id']] = {id: row['unduplicated_client_id']}
        end
      return clients
    end

    def find_first_entries clients, relevent_project_types
      previous_clients = []
      clients.each do |id, client|
        sql = "
          select top 1 first_date_in_program
          from #{GrdaWarehouse::ClientHousingHistory.table_name}
          where record_type = 'entry'
          and unduplicated_client_id = #{id}
          and program_type in (#{relevent_project_types.compact.join(', ')}) 
            and first_date_in_program >= '#{REPORT_START_DATE}'
            and first_date_in_program <= '#{REPORT_END_DATE}'
          order by first_date_in_program asc
        "
        clients[id][:start_date] = @c_grda_warehouse.execute(sql).each.first['first_date_in_program']
      end
      # See if the client was active wthin the two years prior to their start date
      # Specifically, see if we started a program before the first start within the report range
      # and that program is either ongoing or ended within the two years before (not prior)
      # This should encompass all project types (same as 5.2)
      all_project_types = ES + SH + TH + PH
      clients.each do |id, client|
        look_back_until =  LOOKBACK_STOP_DATE.to_date >= (client[:start_date].to_date - 730.days) ? LOOKBACK_STOP_DATE : (client[:start_date].to_date - 730.days).strftime('%Y-%m-%d')
        sql = "
          select top 1 first_date_in_program
          from #{GrdaWarehouse::ClientHousingHistory.table_name}
          where record_type = 'entry'
            and unduplicated_client_id = #{id}
            and program_type in (#{all_project_types.compact.join(', ')}) 
            and first_date_in_program < '#{client[:start_date].to_date.strftime('%Y-%m-%d')}'
            and (last_date_in_program is NULL or last_date_in_program >= '#{look_back_until}')
          order by first_date_in_program asc
        "
        results = @c_grda_warehouse.execute(sql).each
        if results.any?
          # clients[id][:early_start_date] = results.first['first_date_in_program']
          previous_clients << id
        end
      end
      return previous_clients
    end
  end
end
