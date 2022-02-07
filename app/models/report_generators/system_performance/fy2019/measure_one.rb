###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ReportGenerators::SystemPerformance::Fy2019
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
    # SO = [4]
    SO = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:so).flatten(1)

    def run!(debug=false)
      @debug = debug
      # Disable logging so we don't fill the disk
      ActiveRecord::Base.logger.silence do
        calculate()
        Rails.logger.info "Done"
      end # End silence ActiveRecord Log
    end

    def calculate
      if start_report(Reports::SystemPerformance::Fy2019::MeasureOne.first)
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
        homeless_day_count = calculate_days_homeless(id, project_types, stop_project_types, false, true)
        if homeless_day_count > 0
          clients[id] = homeless_day_count
        end
        if index % 100 == 0 && index != 0
          # save our progress, divide by two because we need to loop over these again
          update_report_progress(percent: (((index.to_f / remaining.count) / 4) * 100).round(2))
        end
      end

      client_personal_ids = personal_ids(remaining)

      if clients.size > 0
        @answers[:onea_c2][:value] = clients.size
        @support[:onea_c2][:support] = {
          headers: ['Client ID', 'Personal IDs', 'Days'],
          counts: clients.map do |id, days|
            [
              id,
              client_personal_ids[id].join(', '),
              days,
            ]
          end
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
        homeless_day_count = calculate_days_homeless(id, project_types, stop_project_types, false, true)
        if homeless_day_count > 0
          clients[id] = homeless_day_count
        end
        if index % 100 == 0 && index != 0
          # save our progress, start at 50% because we've already run through once
          update_report_progress(percent: (((index.to_f / remaining.count) / 4) * 100 + 20).round(2))
        end
      end

      client_personal_ids = personal_ids(remaining)

      if clients.size > 0
        @answers[:onea_c3][:value] = clients.count
        @support[:onea_c3][:support] = {
          headers: ['Client ID', 'Personal IDs', 'Days'],
          counts: clients.map do |id, days|
            [
              id,
              client_personal_ids[id].join(', '),
              days,
            ]
          end
        }
        @answers[:onea_e3][:value] = clients.values.reduce(:+) / (clients.count)
        @answers[:onea_h3][:value] = median(clients.values)
      end
    end

    def add_one_b_answers
      calculate_one_b_es_sh_ph()
      calculate_one_b_es_sh_th_ph()
    end

    def calculate_one_b_es_sh_ph
      # Universe is anyone who spent time in ES, SH, PH pre-housed

      project_types = ES + SH + PH
      stop_project_types = TH + PH
      es_sh_scope = clients_in_projects_of_type(project_types: ES + SH).
        select(:client_id)

      es_sh_ids = add_filters(scope: es_sh_scope).distinct.pluck(:client_id)

      ph_pre_housed_scope = clients_in_projects_of_type(project_types: PH).joins(:enrollment).
        where(
          she_t[:first_date_in_program].in(@report_start..@report_end).
          or(e_t[:MoveInDate].in(@report_start..@report_end)).
          or(e_t[:MoveInDate].eq(nil).and(she_t[:last_date_in_program].in(@report_start..@report_end))),
        )

      ph_pre_housed_ids = add_filters(scope: ph_pre_housed_scope).distinct.pluck(:client_id)

      remaining = (es_sh_ids + ph_pre_housed_ids).uniq
      Rails.logger.info "Processing #{remaining.count} clients"

      # Line 1
      clients = {} # Fill this with hashes: {client_id: days_homeless}
      remaining.each_with_index do |id, index|
        homeless_day_count = calculate_days_homeless(id, project_types, stop_project_types, true, true)
        if homeless_day_count > 0
          clients[id] = homeless_day_count
        end
        if index % 100 == 0 && index != 0
          # save our progress, divide by two because we need to loop over these again
          update_report_progress(percent: (((index.to_f / remaining.count) / 4) * 100).round(2))
        end
      end

      client_personal_ids = personal_ids(remaining)

      if clients.size > 0
        @answers[:oneb_c2][:value] = clients.size
        @support[:oneb_c2][:support] = {
          headers: ['Client ID', 'Personal IDs', 'Days'],
          counts: clients.map do |id, days|
            [
              id,
              client_personal_ids[id].join(', '),
              days,
            ]
          end
        }
        @answers[:oneb_e2][:value] = clients.values.reduce(:+) / (clients.size)
        @answers[:oneb_h2][:value] = median(clients.values)
      end
    end

    def calculate_one_b_es_sh_th_ph
      # Universe is anyone who spent time in TH, ES or SH
      # Now include days between first reported homeless date and entry date
      project_types = ES + SH + TH + PH
      stop_project_types = PH
      es_sh_th_scope = clients_in_projects_of_type(project_types: ES + SH + TH).
        select(:client_id)

      es_sh_th_ids = add_filters(scope: es_sh_th_scope).distinct.pluck(:client_id)

      ph_pre_housed_scope = clients_in_projects_of_type(project_types: PH).joins(:enrollment).
        where(
          she_t[:first_date_in_program].in(@report_start..@report_end).
          or(e_t[:MoveInDate].in(@report_start..@report_end)).
          or(e_t[:MoveInDate].eq(nil).and(she_t[:last_date_in_program].in(@report_start..@report_end)))
        )

      ph_pre_housed_ids = add_filters(scope: ph_pre_housed_scope).distinct.pluck(:client_id)

      remaining = (es_sh_th_ids + ph_pre_housed_ids).uniq

      # Line 2
      clients = {} # Fill this with hashes: {client_id: days_homeless}
      remaining.each_with_index do |id, index|
        homeless_day_count = calculate_days_homeless(id, project_types, stop_project_types, true, true)
        if homeless_day_count > 0
          clients[id] = homeless_day_count
        end
        if index % 100 == 0 && index != 0
          # save our progress, start at 50% because we've already run through once
          update_report_progress(percent: (((index.to_f / remaining.count) / 4) * 100 + 75).round(2))
        end
      end

      client_personal_ids = personal_ids(remaining)

      if clients.size > 0
        @answers[:oneb_c3][:value] = clients.count
        @support[:oneb_c3][:support] = {
          headers: ['Client ID', 'Personal IDs', 'Days'],
          counts: clients.map do |id, days|
            [
              id,
              client_personal_ids[id].join(', '),
              days,
            ]
          end
        }
        @answers[:oneb_e3][:value] = clients.values.reduce(:+) / (clients.count)
        @answers[:oneb_h3][:value] = median(clients.values)
      end
    end

    def clients_in_projects_of_type(project_types:)
      GrdaWarehouse::ServiceHistoryEnrollment.entry.
        open_between(start_date: @report_start - 1.day, end_date: @report_end).
        hud_project_type(project_types).
        with_service_between(start_date: @report_start - 1.day, end_date: @report_end)
    end

    def calculate_days_homeless(id, project_types, stop_project_types, include_pre_entry, consider_move_in_date)
      columns = {
        enrollment_id: she_t[:id],
        date: shs_t[:date],
        project_type: she_t[:computed_project_type],
        first_date_in_program: she_t[:first_date_in_program],
        last_date_in_program: she_t[:last_date_in_program],
        DateToStreetESSH: e_t[:DateToStreetESSH],
        MoveInDate: e_t[:MoveInDate],
        DOB: c_t[:DOB],
      }
      #Rails.logger.info "Calculating Days Homeless for: #{id}"
      # Load all bed nights
      all_night_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
        joins(:enrollment, :service_history_services, :client).
        where(client_id: id).
        hud_project_type(PH + TH + ES + SH)

      #all_night_scope = add_filters(scope: all_night_scope)

      all_nights = all_night_scope.
        order(date: :asc).
        pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end
      if include_pre_entry
        # Add fake records for every day between DateToStreetESSH and first_date_in_program.
        # Also add fake records for
        # Find the first entry for each enrollment based on unique project type and first_date in program
        entries = all_nights.select{|m| project_types.include?(m[:project_type])}.index_by{|m| [m[:project_type], m[:first_date_in_program]]}
        entries.each do |_, entry|
          next unless literally_homeless?(client_id: id, enrollment_id: entry[:enrollment_id])
          # 3.917.3 - add any days prior to project entry
          if entry[:DateToStreetESSH].present? && entry[:first_date_in_program] > entry[:DateToStreetESSH]
            start_date = [entry[:DateToStreetESSH]&.to_date, LOOKBACK_STOP_DATE.to_date, entry[:DOB]&.to_date].compact.max
            new_nights = (start_date..entry[:first_date_in_program]).map do |date|
              {
                date: date,
                project_type: 1, # force these days to be ES since that's included in all 1b measures
                enrollment_id: entry[:enrollment_id],
                first_date_in_program: entry[:first_date_in_program],
                DateToStreetESSH: entry[:DateToStreetESSH],
                MoveInDate: entry[:MoveInDate],
              }
            end
            all_nights += new_nights
          end
          # move in date adjustments - These dates will exist as PH, but we want to make sure they get
          # included in the acceptable project types.  Convert the project type of any days pre-move-in
          # for PH to a project type we will be counting
          if PH.include?(entry[:project_type])
            start_date = [entry[:first_date_in_program].to_date, entry[:DOB]&.to_date].compact.max
            stop_date = nil
            if entry[:MoveInDate].present? && entry[:MoveInDate] > entry[:first_date_in_program]
              stop_date = [entry[:MoveInDate], @report_end + 1.day].min
            elsif entry[:MoveInDate].blank?
              stop_date = [entry[:last_date_in_program] - 1.day, @report_end].min rescue @report_end
            end
            next unless stop_date.present?
            date_range = (start_date...stop_date)
            date_range.each do |date|
              check = {
                enrollment_id: entry[:enrollment_id],
                date: date,
                project_type: entry[:project_type],
                first_date_in_program: entry[:first_date_in_program],
                last_date_in_program: entry[:last_date_in_program],
                DateToStreetESSH: entry[:DateToStreetESSH],
                MoveInDate: entry[:MoveInDate],
              }
              matching_night = all_nights.detect do |night|
                night == check
              end
              # convert date to homeless night
              if matching_night.present?
                matching_night[:project_type] = 1 # force these days to be ES since that's included in all 1b measures
              else
                check[:project_type] = 1 # force these days to be ES since that's included in all 1b measures
                all_nights << check
              end
            end
          end
        end
        all_nights.sort_by{|m| m[:date]}
      end
      homeless_days = filter_days_for_homelessness(all_nights, project_types, stop_project_types, consider_move_in_date)
      if homeless_days.any?
        # Find the latest bed night (stopping at the report date end)
        client_end_date = [homeless_days.last.to_date, @report_end ].min
        #Rails.logger.info "Latest Homeless Bed Night: #{client_end_date}"

        # Determine the client's start date
        client_start_date = [client_end_date.to_date - 365.days, LOOKBACK_STOP_DATE.to_date].max
        #Rails.logger.info "Client's initial start date: #{client_start_date}"
        days_before_client_start_date = homeless_days.select do |d|
          d.to_date < client_start_date.to_date
        end
        # Move new start date back based on contiguous homelessness before the start date above
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

    def literally_homeless?(client_id:, enrollment_id:)
      # Literally HUD homeless
      # Clients from ES, SO SH
      es_so_sh_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
        hud_project_type(ES + SO + SH).
        open_between(start_date: @report_start - 1.day, end_date: @report_end).
        with_service_between(start_date: @report_start - 1.day, end_date: @report_end).
        where(she_t[:client_id].eq(client_id).and(she_t[:id].eq(enrollment_id))).
        distinct.
        select(:client_id)

      es_so_sh_client_ids = add_filters(scope: es_so_sh_scope).distinct.pluck(:client_id)

      # Clients from PH & TH under certain conditions
      homeless_living_situations = [16, 1, 18]
      institutional_living_situations = [15, 6, 7, 25, 4, 5]
      housed_living_situations = [29, 14, 2, 32, 36, 35, 28, 19, 3, 31, 33, 34, 10, 20, 21, 11, 8, 9, 99]

      ph_th_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
        hud_project_type(PH + TH).
        open_between(start_date: @report_start - 1.day, end_date: @report_end).
        with_service_between(start_date: @report_start - 1.day, end_date: @report_end).
        where(she_t[:client_id].eq(client_id).and(she_t[:id].eq(enrollment_id))).
        joins(:enrollment).
        where(
          e_t[:LivingSituation].in(homeless_living_situations).
            or(
              e_t[:LivingSituation].in(institutional_living_situations).
                and(e_t[:LOSUnderThreshold].eq(1)).
                and(e_t[:PreviousStreetESSH].eq(1))
            ).
            or(
              e_t[:LivingSituation].in(housed_living_situations).
                and(e_t[:LOSUnderThreshold].eq(1)).
                and(e_t[:PreviousStreetESSH].eq(1))
            )
        ).
        distinct.
        select(:client_id)

      ph_th_client_ids = add_filters(scope: ph_th_scope).distinct.pluck(:client_id)

      literally_homeless = es_so_sh_client_ids + ph_th_client_ids

      # Children may inherit living the living situation from their HoH
      hoh_client = hoh_for_children_without_living_situation(PH + TH, client_id, enrollment_id)

      if hoh_client.present?
        ph_th_hoh_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
            hud_project_type(PH + TH).
            open_between(start_date: @report_start - 1.day, end_date: @report_end).
            with_service_between(start_date: @report_start - 1.day, end_date: @report_end).
            where(she_t[:client_id].eq(hoh_client[:client_id]).and(she_t[:enrollment_group_id].eq(hoh_client[:enrollment_id]))).
            joins(:enrollment).
            where(
                e_t[:LivingSituation].in(homeless_living_situations).
                    or(
                        e_t[:LivingSituation].in(institutional_living_situations).
                            and(e_t[:LOSUnderThreshold].eq(1)).
                            and(e_t[:PreviousStreetESSH].eq(1))
                    ).
                    or(
                        e_t[:LivingSituation].in(housed_living_situations).
                            and(e_t[:LOSUnderThreshold].eq(1)).
                            and(e_t[:PreviousStreetESSH].eq(1))
                    )
            ).
            distinct.
            select(:client_id)

        ph_th_hoh_client_ids = add_filters(scope: ph_th_hoh_scope).distinct.pluck(:client_id)

        literally_homeless += client_id if ph_th_hoh_client_ids.present?
      end

      literally_homeless.include?(client_id)
    end

    # Applies logic described in the Programming Specifications to limit the entries
    # for each day to one, and only those that should be considered based on the project types
    def filter_days_for_homelessness(dates, project_types, stop_project_types, consider_move_in_dates)
      filtered_days = []
      # build a useful hash of arrays
      days = dates.sort_by{|d| d[:date]}.group_by{|d| d[:date]}

      puts "Processing #{dates.count} dates" if @debug
      days.each do |k, bed_nights|
        puts "Looking at: #{bed_nights.count} bed nights on #{k}" if @debug
        # process current day

        # If any entries in the current day have stop_project_types, and move in date is before
        # the current date, or all of the entries have stop_project_types, throw out the entire day
        in_stop_project = false
        has_countable_project = false
        bed_nights.each do |night|
          # Ignore nights in a project that are on the date of exit
          next if is_on_exit(night, k)

          has_countable_project =  has_countable_project || has_countable_project_on?(night, stop_project_types)
          in_stop_project =  in_stop_project || in_stop_project_on?(night, k, stop_project_types, consider_move_in_dates)
        end
        if  has_countable_project && (! in_stop_project)
          filtered_days << k
        end
      end
      puts "Found: #{filtered_days.count}" if @debug
      puts "#{filtered_days.map{|day| [ day.month, day.year] }.uniq}" if @debug
      return filtered_days.sort
    end

    private def has_countable_project_on?(night, stop_project_types)
      (! stop_project_types.include?(night[:project_type]))
    end

    private def in_stop_project_on?(night, date, stop_project_types, consider_move_in_dates)
      if consider_move_in_dates && PH.include?(night[:project_type])
        return (stop_project_types.include?(night[:project_type]) && (night[:MoveInDate].present? && night[:MoveInDate] <= date))
      else
        return (stop_project_types.include?(night[:project_type]) && (night[:MoveInDate].blank? || night[:MoveInDate] <= date))
      end
    end

    private def is_on_exit(night, date)
      night[:last_date_in_program] == date
    end

    def median array
      mid = array.size / 2
      sorted = array.sort
      array.length.odd? ? sorted[mid] : (sorted[mid] + sorted[mid - 1]) / 2
    end

    def children_without_living_situation(project_types)
      # 99 = Not collected
      living_situation_not_collected = [99]

      @child_ids ||= {}
      @child_ids[project_types] ||= begin
        child_candidates_scope =  GrdaWarehouse::ServiceHistoryEnrollment.entry.
            hud_project_type(project_types).
            open_between(start_date: @report_start - 1.day, end_date: @report_end).
            with_service_between(start_date: @report_start - 1.day, end_date: @report_end).
            joins(:enrollment, :client).
            where(
                e_t[:LivingSituation].in(living_situation_not_collected).or(e_t[:LivingSituation].eq(nil)),
                c_t[:DOB].not_eq(nil).and(c_t[:DOB].lteq(@report_start - 17.years)),
            ).
            distinct.
            select(:client_id)

        child_candidates = add_filters(scope: child_candidates_scope).
          pluck(
            :client_id,
            c_t[:DOB],
            e_t[:EntryDate],
            :age,
            :head_of_household_id,
            :household_id,
            :enrollment_group_id,
          )

        child_id_to_hoh = {}
        child_candidates.each do |(client_id, dob, entry_date, age, hoh_id, household_id, enrollment_group_id)|
          age = age_for_report dob: dob, entry_date: entry_date, age: age
          if age.present? && age <= 17
            child_id_to_hoh[[client_id, enrollment_group_id]] = head_of_household_for(project_types, hoh_id, household_id)
          end
        end
        child_id_to_hoh
      end
    end

    def hoh_client_ids(project_types)
      @hoh_to_client_id ||= {}
      @hoh_to_client_id[project_types] ||= begin
        GrdaWarehouse::ServiceHistoryEnrollment.exit.
          hud_project_type(project_types).
          open_between(start_date: @report_start - 1.day, end_date: @report_end).
          with_service_between(start_date: @report_start - 1.day, end_date: @report_end).
          joins(:client).
          where(she_t[:head_of_household].eq(true)).
          distinct.
          pluck(
            :head_of_household_id,
            :client_id,
            :enrollment_group_id,
            :household_id
          ).map do |(hoh_id, client_id, enrollment_id, household_id)|
            [[hoh_id, household_id], { client_id: client_id, enrollment_id: enrollment_id }]
          end.to_h
      end
    end

    def head_of_household_for(project_types, client_id, household_id)
      hoh_client_ids(project_types)[[client_id, household_id]]
    end

    def hoh_for_children_without_living_situation(project_types, client_id, enrollment_id)
      children_without_living_situation(project_types)[[client_id, enrollment_id]]
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
