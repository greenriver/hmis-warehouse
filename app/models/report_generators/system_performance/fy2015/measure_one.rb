module ReportGenerators::SystemPerformance::Fy2015
  class MeasureOne
    # TODO: 2016 report only needs measure 1a, in 2017 we need to build Measure 1b
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

      # Overview: Calculate the length of time each client has been homeless within a window
      # Column B is the distinct clients homeless
      # Column D is the Average of the total time homeless
      # Column G is the Median of the total time homeless
      results = {
        onea_a2: {
          title: nil,
          value: 'Persons in ES and SH',
        },
        onea_a3: {
          title: nil,
          value: 'Persons in ES, SH and TH',
        },
        onea_b1: {
          title: nil,
          value: 'Previous FY',
        },
        onea_b2: {
          title: 'Persons in ES and SH (previous FY)',
          value: nil,
        },
        onea_b3: {
          title: 'Persons in ES, SH and TH (previous FY)',
          value: nil,
        },
        onea_c1: {
          title: nil,
          value: 'Current FY',
        },
        onea_c2: {
          title: 'Persons in ES and SH (current FY)',
          value: 0,
        },
        onea_c3: {
          title: 'Persons in ES, SH and TH (current FY)',
          value: 0,
        },
        onea_d1: {
          title: nil,
          value: 'Previous FY Average LOT Homeless',
        },
        onea_d2: {
          title: 'Persons in ES and SH (previous FY average LOT homeless)',
          value: nil,
        },
        onea_d3: {
          title: 'Persons in ES, SH and TH (previous FY average LOT homeless)',
          value: nil,
        },
        onea_e1: {
          title: nil,
          value: 'Current FY Average LOT Homeless',
        },
        onea_e2: {
          title: 'Persons in ES and SH (current FY average LOT homeless)',
          value: 0,
        },
        onea_e3: {
          title: 'Persons in ES, SH and TH (current FY average LOT homeless)',
          value: 0,
        },
        onea_f1: {
          title: nil,
          value: 'Difference',
        },
        onea_f2: {
          title: 'Persons in ES and SH (difference)',
          value: nil,
        },
        onea_f3: {
          title: 'Persons in ES, SH and TH (difference)',
          value: nil,
        },
        onea_g1: {
          title: nil,
          value: 'Previous FY Median LOT Homeless',
        },
        onea_g2: {
          title: 'Persons in ES and SH (previous FY median LOT homeless)',
          value: nil,
        },
        onea_g3: {
          title: 'Persons in ES, SH and TH (previous FY median LOT homeless)',
          value: nil,
        },
        onea_h1: {
          title: nil,
          value: 'Current FY Median LOT Homeless',
        },
        onea_h2: {
          title: 'Persons in ES and SH (current FY median LOT homeless)',
          value: 0,
        },
        onea_h3: {
          title: 'Persons in ES, SH and TH (current FY median LOT homeless)',
          value: 0,
        },
        onea_i1: {
          title: nil,
          value: 'Difference',
        },
        onea_i2: {
          title: 'Persons in ES and SH (difference)',
          value: nil,
        },
        onea_i3: {
          title: 'Persons in ES, SH and TH (difference)',
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
      # 
      # Line 1 looks at (1, 8)
      # Line 2 looks at (1, 8, 2)      
       
      # Find the first queued report
      report = ReportResult.where(report: Reports::SystemPerformance::Fy2015::MeasureOne.first).where(percent_complete: 0).first
      return unless report.present? 
      Rails.logger.info "Starting report #{report.report.name}"
      report.update_attributes(percent_complete: 0.01)
      # Universe is anyone who spent time in ES or SH
      remaining = GrdaWarehouse::ClientHousingHistory.where("[date] >= '#{REPORT_START_DATE}'").where("[date] <= '#{REPORT_END_DATE}'").where(record_type: 'bed_night').where(program_type: ES + SH).select(:unduplicated_client_id).distinct.pluck(:unduplicated_client_id)
      Rails.logger.info "Processing #{remaining.count} clients"

      # Line 1
      clients = {} # Fill this with hashes: {client_id: days_homeless}
      project_types = ES + SH
      stop_project_types = PH + TH
      remaining.each_with_index do |id, index|
        homeless_day_count = calculate_days_homeless id, project_types, stop_project_types
        if homeless_day_count > 0
          clients[id] = homeless_day_count
        end
        if index % 100 == 0 && index != 0
          # save our progress, divide by two because we need to loop over these again
          report.update_attributes(percent_complete: (((index.to_f / remaining.count) / 2) * 100).round(2))
        end
      end
      # puts clients.inspect
      results[:onea_c2][:value] = clients.size
      results[:onea_e2][:value] = clients.values.reduce(:+) / (clients.size)
      results[:onea_h2][:value] = median(clients.values)

      # Universe is anyone who spent time in TH, ES or SH
      remaining = GrdaWarehouse::ClientHousingHistory.where("[date] >= '#{REPORT_START_DATE}'").where("[date] <= '#{REPORT_END_DATE}'").where(record_type: 'bed_night').where(program_type: TH + ES + SH).select(:unduplicated_client_id).distinct.pluck(:unduplicated_client_id)
      # Line 2
      clients = {} # Fill this with hashes: {client_id: days_homeless}
      project_types = ES + SH + TH
      stop_project_types = PH
      remaining.each_with_index do |id, index|
        homeless_day_count = calculate_days_homeless id, project_types, stop_project_types
        if homeless_day_count > 0
          clients[id] = homeless_day_count
        end
        if index % 100 == 0 && index != 0
          # save our progress, start at 50% because we've already run through once
          report.update_attributes(percent_complete: (((index.to_f / remaining.count) / 2) * 100 + 50).round(2))
        end
      end
      # puts clients.inspect
      results[:onea_c3][:value] = clients.count
      results[:onea_e3][:value] = clients.values.reduce(:+) / (clients.count)
      results[:onea_h3][:value] = median(clients.values)

      Rails.logger.info results.inspect
      report.update_attributes(percent_complete: 100, results: results, completed_at: Time.now)
      
    end

    private
      def calculate_days_homeless id, project_types, stop_project_types
        #Rails.logger.info "Calculating Days Homelesss for: #{id}"
        # Load all bed nights 
        all_nights = GrdaWarehouse::ClientHousingHistory.where(unduplicated_client_id: id).where(record_type: 'bed_night').where(program_type: PH + TH + ES + SH).order(date: :asc).select(:date, :program_type)
        homeless_days = filter_days_for_homelessness all_nights, project_types, stop_project_types

        if homeless_days.any?
          # Find the latest bed night (stopping at the report date end)
          client_end_date = [homeless_days.last.to_date, REPORT_END_DATE.to_date].min
          #Rails.logger.info "Latest Homeless Bed Night: #{client_end_date}"

          # Determine the client's start date
          client_start_date = [client_end_date.to_date - 365.days, LOOKBACK_STOP_DATE.to_date].max
          #Rails.logger.info "Client's initial start date: #{client_start_date}"
          days_before_client_start_date = homeless_days.select { |d| d.to_date < client_start_date.to_date}
          new_client_start_date = client_start_date.to_date
          days_before_client_start_date.reverse_each do |d|
            if d.to_date == new_client_start_date.to_date - 1.day
              new_client_start_date = d.to_date
            else
              # Non-contiguous
              break
            end
          end
          client_start_date = [new_client_start_date.to_date, LOOKBACK_STOP_DATE.to_date].max
          #Rails.logger.info "Client's new start date: #{client_start_date}"

          # Remove any days outside of client_start_date and client_end_date
          #Rails.logger.info "Days homeless before limits #{homeless_days.count}"
          homeless_days.delete_if { |d| d.to_date < client_start_date.to_date || d.to_date > client_end_date.to_date }
          #Rails.logger.info "Days homeless after limits #{homeless_days.count}"
        end
        homeless_days.uniq.count
      end

      # Applies logic described in the Programming Specifications to limit the entries 
      # for each day to one, and only those that should be considred based on the project types
      def filter_days_for_homelessness dates, project_types, stop_project_types
        filtered_days = []
        # build a useful hash of arrays
        days = dates.group_by{|d| d.date}

        # puts "Processing #{dates.count} dates"
        days.each do |k, bed_nights|
          # puts "Looking at: #{v.inspect}"
          # process current day

          # If any entries in the current day have stop_project_types, 
          #   throw out the entire day 
          keep = true
          bed_nights.each do |night| 
            if stop_project_types.include? night[:program_type]
              keep = false
            end
          end
          # puts "removed stop projects: #{v.inspect}"
          if keep
            filtered_days << k
          end
        end
        # puts "Found: #{filtered_days.count}"
        return filtered_days
      end
      def median array
        mid = array.size / 2
        sorted = array.sort
        array.length.odd? ? sorted[mid] : (sorted[mid] + sorted[mid - 1]) / 2 
      end
  end
end
