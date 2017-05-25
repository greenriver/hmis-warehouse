module ReportGenerators::SystemPerformance::Fy2016
  class MeasureOne < Base
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
    
    def calculate
      if start_report(Reports::SystemPerformance::Fy2016::MeasureOne.first)
        set_report_start_and_end()
        # Overview: Calculate the length of time each client has been homeless within a window
        # Column B is the distinct clients homeless
        # Column D is the Average of the total time homeless
        # Column G is the Median of the total time homeless
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
        # 14: Coordinated Assessment
        # 
        # Line 1 looks at (1, 8)
        # Line 2 looks at (1, 8, 2)      
        
        Rails.logger.info "Starting report #{@report.report.name}"
        add_one_a_answers()
        update_report_progress(percent: 50)

        add_one_b_answers()
      
        Rails.logger.info @answers.inspect
        
        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    def add_one_a_answers
      calculate_one_a_es_sh()
      calculate_one_a_es_sh_th()
      
    end

    def calculate_one_a_es_sh
      # Universe is anyone who spent time in ES or SH
      # 
      # This uses service records instead of entry records, it is much slower, but 
      # excludes clients with no service records for an enrollment
      # remaining = GrdaWarehouse::ServiceHistory.service.
      #   service_within_date_range(start_date: @report.options['report_start'].to_date - 1.day, end_date: @report.options['report_end'].to_date).
      #   where(project_type: GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:es, :sh).flatten(1)).
      #   select(:client_id).distinct.pluck(:client_id)

      project_types = ES + SH
      stop_project_types = PH + TH
      remaining_scope = clients_in_projects_of_type(project_types: project_types).
        select(:client_id)
      
      remaining_scope = add_filters(scope: remaining_scope)

      remaining = remaining_scope.distinct.pluck(:client_id)
      Rails.logger.info "Processing #{remaining.count} clients"
      
      # Line 1
      clients = {} # Fill this with hashes: {client_id: days_homeless}
      remaining.each_with_index do |id, index|
        homeless_day_count = calculate_days_homeless(id, project_types, stop_project_types)
        if homeless_day_count > 0
          clients[id] = homeless_day_count
        end
        if index % 100 == 0 && index != 0
          # save our progress, divide by two because we need to loop over these again
          update_report_progress(percent: (((index.to_f / remaining.count) / 4) * 100).round(2))
        end
      end
      if clients.size > 0
        @answers[:onea_c2][:value] = clients.size
        @support[:onea_c2][:support] = {
          headers: ['Client ID', 'Days'],
          counts: clients.map{|id, days| [id, days]}
        }
        @answers[:onea_e2][:value] = clients.values.reduce(:+) / (clients.size)
        @answers[:onea_h2][:value] = median(clients.values)
      end
    end

    def calculate_one_a_es_sh_th
      # Universe is anyone who spent time in TH, ES or SH
      project_types = ES + SH + TH
      stop_project_types = PH
      remaining_scope = clients_in_projects_of_type(project_types: project_types).
        select(:client_id)

      remaining_scope = add_filters(scope: remaining_scope)

      remaining = remaining_scope.distinct.pluck(:client_id)

      # Line 2
      clients = {} # Fill this with hashes: {client_id: days_homeless}
      
      remaining.each_with_index do |id, index|
        homeless_day_count = calculate_days_homeless(id, project_types, stop_project_types)
        if homeless_day_count > 0
          clients[id] = homeless_day_count
        end
        if index % 100 == 0 && index != 0
          # save our progress, start at 50% because we've already run through once
          update_report_progress(percent: (((index.to_f / remaining.count) / 4) * 100 + 20).round(2))
        end
      end
      if clients.size > 0
        @answers[:onea_c3][:value] = clients.count
        @support[:onea_c3][:support] = {
          headers: ['Client ID', 'Days'],
          counts: clients.map{|id, days| [id, days]}
        }
        @answers[:onea_e3][:value] = clients.values.reduce(:+) / (clients.count)
        @answers[:onea_h3][:value] = median(clients.values)
      end
    end

    def add_one_b_answers
      calculate_one_b_es_sh()
      calculate_one_b_es_sh_th()      
    end

    def calculate_one_b_es_sh
      # Universe is anyone who spent time in ES or SH
      # Now include days between first reported homeless date and entry date
      project_types = ES + SH
      stop_project_types = PH + TH
      remaining_scope = clients_in_projects_of_type(project_types: project_types).
        select(:client_id)

      remaining_scope = add_filters(scope: remaining_scope)

      remaining = remaining_scope.distinct.pluck(:client_id)
      Rails.logger.info "Processing #{remaining.count} clients"
      
      # Line 1
      clients = {} # Fill this with hashes: {client_id: days_homeless}
      remaining.each_with_index do |id, index|
        homeless_day_count = calculate_days_homeless(id, project_types, stop_project_types, true)
        if homeless_day_count > 0
          clients[id] = homeless_day_count
        end
        if index % 100 == 0 && index != 0
          # save our progress, divide by two because we need to loop over these again
          update_report_progress(percent: (((index.to_f / remaining.count) / 4) * 100 + 50).round(2))
        end
      end

      if clients.size > 0
        @answers[:oneb_c2][:value] = clients.size
        @support[:oneb_c2][:support] = {
          headers: ['Client ID', 'Days'],
          counts: clients.map{|id, days| [id, days]}
        }
        @answers[:oneb_e2][:value] = clients.values.reduce(:+) / (clients.size)
        @answers[:oneb_h2][:value] = median(clients.values)
      end
    end

    def calculate_one_b_es_sh_th
      # Universe is anyone who spent time in TH, ES or SH
      # Now include days between first reported homeless date and entry date
      project_types = ES + SH + TH
      stop_project_types = PH
      remaining_scope = clients_in_projects_of_type(project_types: project_types).
        select(:client_id)

      remaining_scope = add_filters(scope: remaining_scope)
      
      remaining = remaining_scope.distinct.pluck(:client_id)

      # Line 2
      clients = {} # Fill this with hashes: {client_id: days_homeless}
      remaining.each_with_index do |id, index|
        homeless_day_count = calculate_days_homeless(id, project_types, stop_project_types, true)
        if homeless_day_count > 0
          clients[id] = homeless_day_count
        end
        if index % 100 == 0 && index != 0
          # save our progress, start at 50% because we've already run through once
          update_report_progress(percent: (((index.to_f / remaining.count) / 4) * 100 + 75).round(2))
        end
      end
      
      if clients.size > 0
        @answers[:oneb_c3][:value] = clients.count
        @support[:oneb_c3][:support] = {
          headers: ['Client ID', 'Days'],
          counts: clients.map{|id, days| [id, days]}
        }
        @answers[:oneb_e3][:value] = clients.values.reduce(:+) / (clients.count)
        @answers[:oneb_h3][:value] = median(clients.values)
      end
    end
    
    def clients_in_projects_of_type project_types:
      GrdaWarehouse::ServiceHistory.
        entry_within_date_range(start_date: @report_start - 1.day, end_date: @report_end).
          hud_project_type(project_types)
    end

    def calculate_days_homeless id, project_types, stop_project_types, include_pre_entry=false
      et = GrdaWarehouse::Hud::Enrollment.arel_table
      sh_t = GrdaWarehouse::ServiceHistory.arel_table
      columns = {
        date: sh_t[:date].as(:date).to_sql, 
        project_type: act_as_project_overlay, 
        first_date_in_program: sh_t[:first_date_in_program].as(:first_date_in_program).to_sql,
        DateToStreetESSH: et[:DateToStreetESSH].as(:DateToStreetESSH).to_sql,
      }
      #Rails.logger.info "Calculating Days Homelesss for: #{id}"
      # Load all bed nights
      all_night_scope = GrdaWarehouse::ServiceHistory.
        service.
        joins(:enrollment, :project).
        where(client_id: id).
        hud_project_type(PH + TH + ES + SH)

      all_night_scope = add_filters(scope: all_night_scope)

      all_nights = all_night_scope.
        order(date: :asc).
        pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end
      if include_pre_entry
        # Add fake records for every day between DateToStreetESSH and first_date_in_program.
        # Find the first entry for each enrollment based on unique project type and first_date in program
        entries = all_nights.select{|m| project_types.include?(m[:project_type])}.index_by{|m| [m[:project_type], m[:first_date_in_program]]}
        entries.each do |_, entry|
          if entry[:DateToStreetESSH].present? && entry[:first_date_in_program] > entry[:DateToStreetESSH]
            start_date = [entry[:DateToStreetESSH].to_date, LOOKBACK_STOP_DATE.to_date].max
            new_nights = (start_date..entry[:first_date_in_program]).map do |date|
              {
                date: date,
                project_type: entry[:project_type],
                first_date_in_program: entry[:first_date_in_program],
                DateToStreetESSH: entry[:DateToStreetESSH],
              }
            end
            all_nights += new_nights
          end
        end
        all_nights.sort_by{|m| m[:date]}
      end
      homeless_days = filter_days_for_homelessness(all_nights, project_types, stop_project_types)

      if homeless_days.any?
        # Find the latest bed night (stopping at the report date end)
        client_end_date = [homeless_days.last.to_date, @report.options['report_end'].to_date].min
        #Rails.logger.info "Latest Homeless Bed Night: #{client_end_date}"

        # Determine the client's start date
        client_start_date = [client_end_date.to_date - 365.days, LOOKBACK_STOP_DATE.to_date].max
        #Rails.logger.info "Client's initial start date: #{client_start_date}"
        days_before_client_start_date = homeless_days.select do |d| 
          d.to_date < client_start_date.to_date
        end
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
      days = dates.group_by{|d| d[:date]}

      # puts "Processing #{dates.count} dates"
      days.each do |k, bed_nights|
        # puts "Looking at: #{v.inspect}"
        # process current day

        # If any entries in the current day have stop_project_types, 
        #   throw out the entire day 
        keep = true
        bed_nights.each do |night| 
          if stop_project_types.include? night[:project_type]
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

    def setup_questions
      {
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
        oneb_a2: {
          title: nil,
          value: 'Persons in ES and SH',
        },
        oneb_a3: {
          title: nil,
          value: 'Persons in ES, SH and TH',
        },
        oneb_b1: {
          title: nil,
          value: 'Previous FY',
        },
        oneb_b2: {
          title: 'Persons in ES and SH (previous FY)',
          value: nil,
        },
        oneb_b3: {
          title: 'Persons in ES, SH and TH (previous FY)',
          value: nil,
        },
        oneb_c1: {
          title: nil,
          value: 'Current FY',
        },
        oneb_c2: {
          title: 'Persons in ES and SH (current FY)',
          value: 0,
        },
        oneb_c3: {
          title: 'Persons in ES, SH and TH (current FY)',
          value: 0,
        },
        oneb_d1: {
          title: nil,
          value: 'Previous FY Average LOT Homeless',
        },
        oneb_d2: {
          title: 'Persons in ES and SH (previous FY average LOT homeless)',
          value: nil,
        },
        oneb_d3: {
          title: 'Persons in ES, SH and TH (previous FY average LOT homeless)',
          value: nil,
        },
        oneb_e1: {
          title: nil,
          value: 'Current FY Average LOT Homeless',
        },
        oneb_e2: {
          title: 'Persons in ES and SH (current FY average LOT homeless)',
          value: 0,
        },
        oneb_e3: {
          title: 'Persons in ES, SH and TH (current FY average LOT homeless)',
          value: 0,
        },
        oneb_f1: {
          title: nil,
          value: 'Difference',
        },
        oneb_f2: {
          title: 'Persons in ES and SH (difference)',
          value: nil,
        },
        oneb_f3: {
          title: 'Persons in ES, SH and TH (difference)',
          value: nil,
        },
        oneb_g1: {
          title: nil,
          value: 'Previous FY Median LOT Homeless',
        },
        oneb_g2: {
          title: 'Persons in ES and SH (previous FY median LOT homeless)',
          value: nil,
        },
        oneb_g3: {
          title: 'Persons in ES, SH and TH (previous FY median LOT homeless)',
          value: nil,
        },
        oneb_h1: {
          title: nil,
          value: 'Current FY Median LOT Homeless',
        },
        oneb_h2: {
          title: 'Persons in ES and SH (current FY median LOT homeless)',
          value: 0,
        },
        oneb_h3: {
          title: 'Persons in ES, SH and TH (current FY median LOT homeless)',
          value: 0,
        },
        oneb_i1: {
          title: nil,
          value: 'Difference',
        },
        oneb_i2: {
          title: 'Persons in ES and SH (difference)',
          value: nil,
        },
        oneb_i3: {
          title: 'Persons in ES, SH and TH (difference)',
          value: nil,
        },
      }
    end
  end
end
