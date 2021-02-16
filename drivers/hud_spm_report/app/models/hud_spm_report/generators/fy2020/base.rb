###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Generates the HUD SPM Report Data
# See https://files.hudexchange.info/resources/documents/System-Performance-Measures-HMIS-Programming-Specifications.pdf
# for specifications

module HudSpmReport::Generators::Fy2020
  class Base < ::HudReports::QuestionBase
    delegate :client_scope, to: :@generator

    def self.question_number
      raise 'TODO'.freeze
    end

    LOOKBACK_STOP_DATE = '2012-10-01'.freeze

    ES = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:es).flatten(1)
    SH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:sh).flatten(1)
    TH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:th).flatten(1)
    PH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:ph).flatten(1)

    SO = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:so).flatten(1)
    RRH = [13].freeze
    PH_PSH = [3, 9, 10].freeze

    # private def universe
    #   add_clients
    #   # unless clients_populated?
    #   #@universe ||= @report.universe(self.class.question_number)
    # end

    private def add_clients
      @debug = true
      client_scope.find_in_batches do |batch|
        enrollments_for_batch = enrollment_scope.where(
          client_id: batch.map(&:id),
        )

        # the enrollments scope does the preloads
        # so use those instances
        enrollments_for_batch.group_by(
          &:client
        ).each do |client, client_enrollments|
          row = {
            report_instance_id: @report.id,
            client_id: client.id,
            data_source_id: client.data_source_id,
            dob: client.DOB,
            m1a_es_sh_days: calculate_days_homeless(client_enrollments, ES + SH, PH + TH, false, true),
            m1a_es_sh_th_days: calculate_days_homeless(client_enrollments, ES + SH + TH, TH, false, true),
            m1b_es_sh_ph_days: calculate_days_homeless(client_enrollments, ES + SH + PH, TH + PH, true, true),
            m1b_es_sh_th_ph_days: calculate_days_homeless(client_enrollments, ES + SH + TH + PH, PH, true, true),
            system_stayer: nil,
            exited_in_days: nil,
            pit_project_type: nil,
          }
          pp row
        end
      end
    end

    private def enrollment_scope
      scope = GrdaWarehouse::ServiceHistoryEnrollment.
        entry.open_between(
          start_date: LOOKBACK_STOP_DATE,
          end_date: @report.end_date,
        ) # .hud_project_type(PH + TH + ES + SH)

      scope = scope.in_project(@report.project_ids) if @report.project_ids.present? # for consistency with client_scope

      scope.preload(
        :client,
        :enrollment,
        :service_history_services,
      )
    end

    # Calculate the number of unique days homeless given:
    #
    # sh_enrollements: an Array(GrdaWarehouse::ServiceHistoryEnrollments) for a client with suitable preloads
    #   covering all dates that could contribute to this report
    # project_types: Array(HUD.oroject_types.keys)
    # stop_project_types: Array(HUD.oroject_types.keys)
    # include_pre_entry: boolean true to include days before entry
    # consider_move_in_date: boolean handle time between [project start] and [housing move-in].
    #
    # The flags are set like so
    # Measure 1a / Metric 1: Persons in ES and SH – do not include data from element 3.917.
    # Measure 1a / Metric 2: Persons in ES, SH, and TH – do not include data from element 3.917.
    # Measure 1b / Metric 1: Persons in ES, SH, and PH – include data from element 3.917 and time between [project start] and [housing move-in].
    # Measure 1b / Metric 2: Persons in ES, SH, TH, and PH – include data from element 3.917 and time between [project start] and [housing move-in].
    def calculate_days_homeless(sh_enrollements, project_types, stop_project_types, include_pre_entry, consider_move_in_date)
      all_nights = sh_enrollements.map do |e|
        {
          client_id: e.client_id,
          enrollment_id: e.id,
          date: e.date,
          project_type: e.computed_project_type,
          first_date_in_program: e.first_date_in_program,
          last_date_in_program: e.last_date_in_program,
          DateToStreetESSH: e.enrollment.DateToStreetESSH,
          MoveInDate: e.enrollment.MoveInDate,
          DOB: e.client.DOB,
        }
      end

      if include_pre_entry
        all_nights = generate_pre_entry_dates(
          all_nights,
          project_types,
          stop_project_types,
          consider_move_in_date,
        )
      end

      homeless_days = filter_days_for_homelessness(
        all_nights,
        stop_project_types,
        consider_move_in_date,
      )

      if homeless_days.any?
        # Find the latest bed night (stopping at the report date end)
        client_end_date = [homeless_days.last.to_date, @report.end_date].min
        # Rails.logger.info "Latest Homeless Bed Night: #{client_end_date}"

        # Determine the client's start date
        client_start_date = [client_end_date.to_date - 365.days, LOOKBACK_STOP_DATE.to_date].max
        # Rails.logger.info "Client's initial start date: #{client_start_date}"
        days_before_client_start_date = homeless_days.select do |d|
          d.to_date < client_start_date.to_date
        end
        # Move new start date back based on contiguous homelessness before the start date above
        new_client_start_date = client_start_date.to_date
        days_before_client_start_date.reverse_each do |d|
          if d.to_date == new_client_start_date.to_date - 1.day # rubocop:disable Style/GuardClause
            new_client_start_date = d.to_date
          else
            # Non-contiguous
            break
          end
        end
        client_start_date = [new_client_start_date.to_date, LOOKBACK_STOP_DATE.to_date].max
        # Rails.logger.info "Client's new start date: #{client_start_date}"

        # Remove any days outside of client_start_date and client_end_date
        # Rails.logger.info "Days homeless before limits #{homeless_days.count}"
        homeless_days.delete_if { |d| d.to_date < client_start_date.to_date || d.to_date > client_end_date.to_date }
        # Rails.logger.info "Days homeless after limits #{homeless_days.count}"
      end

      if @debug
        info = {
          client_id: sh_enrollements.first.client_id,
          project_types: project_types,
          stop_project_types: stop_project_types,
          include_pre_entry: include_pre_entry,
          consider_move_in_date: consider_move_in_date,
          all_nights: all_nights,
        }
        pp info
      end

      homeless_days.uniq.count
    end

    def generate_pre_entry_dates(all_nights, project_types, _stop_project_types, _consider_move_in_dates)
      # Add fake records for every day between DateToStreetESSH and first_date_in_program.
      # Also add fake records for
      # Find the first entry for each enrollment based on unique project type and first_date in program
      entries = all_nights.select { |m| project_types.include?(m[:project_type]) }.index_by { |m| [m[:project_type], m[:first_date_in_program]] }
      entries.each do |_, entry|
        next unless literally_homeless?(entry)

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
        next unless PH.include?(entry[:project_type])

        start_date = [entry[:first_date_in_program].to_date, entry[:DOB]&.to_date].compact.max
        stop_date = nil
        if entry[:MoveInDate].present? && entry[:MoveInDate] > entry[:first_date_in_program]
          stop_date = [entry[:MoveInDate], @report_end + 1.day].min
        elsif entry[:MoveInDate].blank?
          stop_date = begin
                          [entry[:last_date_in_program] - 1.day, @report_end].min
                        rescue StandardError
                          @report_end
                        end
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

      all_nights.sort_by { |m| m[:date] }
    end

    # Applies logic described in the Programming Specifications to limit the entries
    # for each day to one, and only those that should be considered based on the project types
    def filter_days_for_homelessness(dates, stop_project_types, consider_move_in_dates)
      filtered_days = []
      # build a useful hash of arrays
      days = dates.group_by { |d| d[:date] }

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
          next if on_exit_night?(night, k)

          has_countable_project ||= countable_project_on?(night, stop_project_types)
          in_stop_project ||= in_stop_project_on?(night, k, stop_project_types, consider_move_in_dates)
        end
        filtered_days << k if has_countable_project && ! in_stop_project
      end
      puts "Found: #{filtered_days.count}" if @debug
      puts filtered_days.map { |day| [day.month, day.year] }.uniq.to_s if @debug
      return filtered_days.sort
    end

    private def countable_project_on?(night, stop_project_types)
      ! stop_project_types.include?(night[:project_type])
    end

    private def in_stop_project_on?(night, date, stop_project_types, consider_move_in_dates)
      if consider_move_in_dates && PH.include?(night[:project_type]) # rubocop:disable Style/GuardClause
        return (stop_project_types.include?(night[:project_type]) && (night[:MoveInDate].present? && night[:MoveInDate] <= date))
      else
        return (stop_project_types.include?(night[:project_type]) && (night[:MoveInDate].blank? || night[:MoveInDate] <= date))
      end
    end

    private def on_exit_night?(night, date)
      night[:last_date_in_program] == date
    end

    private def literally_homeless?(_night)
      false
      # # Literally HUD homeless
      # # Clients from ES, SO SH
      # es_so_sh_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
      #   hud_project_type(ES + SO + SH).
      #   open_between(start_date: @report_start - 1.day, end_date: @report_end).
      #   with_service_between(start_date: @report_start - 1.day, end_date: @report_end).
      #   where(she_t[:client_id].eq(client_id).and(she_t[:id].eq(enrollment_id))).
      #   distinct.
      #   select(:client_id)

      # es_so_sh_client_ids = add_filters(scope: es_so_sh_scope).distinct.pluck(:client_id)

      # # Clients from PH & TH under certain conditions
      # homeless_living_situations = [16, 1, 18]
      # institutional_living_situations = [15, 6, 7, 25, 4, 5]
      # housed_living_situations = [29, 14, 2, 32, 36, 35, 28, 19, 3, 31, 33, 34, 10, 20, 21, 11, 8, 9, 99]

      # ph_th_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
      #   hud_project_type(PH + TH).
      #   open_between(start_date: @report_start - 1.day, end_date: @report_end).
      #   with_service_between(start_date: @report_start - 1.day, end_date: @report_end).
      #   where(she_t[:client_id].eq(client_id).and(she_t[:id].eq(enrollment_id))).
      #   joins(:enrollment).
      #   where(
      #     e_t[:LivingSituation].in(homeless_living_situations).
      #       or(
      #         e_t[:LivingSituation].in(institutional_living_situations).
      #           and(e_t[:LOSUnderThreshold].eq(1)).
      #           and(e_t[:PreviousStreetESSH].eq(1))
      #       ).
      #       or(
      #         e_t[:LivingSituation].in(housed_living_situations).
      #           and(e_t[:LOSUnderThreshold].eq(1)).
      #           and(e_t[:PreviousStreetESSH].eq(1))
      #       )
      #   ).
      #   distinct.
      #   select(:client_id)

      # ph_th_client_ids = add_filters(scope: ph_th_scope).distinct.pluck(:client_id)

      # literally_homeless = es_so_sh_client_ids + ph_th_client_ids

      # # Children may inherit living the living situation from their HoH
      # hoh_client = hoh_for_children_without_living_situation(PH + TH, client_id, enrollment_id)

      # if hoh_client.present?
      #   ph_th_hoh_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
      #       hud_project_type(PH + TH).
      #       open_between(start_date: @report_start - 1.day, end_date: @report_end).
      #       with_service_between(start_date: @report_start - 1.day, end_date: @report_end).
      #       where(she_t[:client_id].eq(hoh_client[:client_id]).and(she_t[:enrollment_group_id].eq(hoh_client[:enrollment_id]))).
      #       joins(:enrollment).
      #       where(
      #           e_t[:LivingSituation].in(homeless_living_situations).
      #               or(
      #                   e_t[:LivingSituation].in(institutional_living_situations).
      #                       and(e_t[:LOSUnderThreshold].eq(1)).
      #                       and(e_t[:PreviousStreetESSH].eq(1))
      #               ).
      #               or(
      #                   e_t[:LivingSituation].in(housed_living_situations).
      #                       and(e_t[:LOSUnderThreshold].eq(1)).
      #                       and(e_t[:PreviousStreetESSH].eq(1))
      #               )
      #       ).
      #       distinct.
      #       select(:client_id)

      #   ph_th_hoh_client_ids = add_filters(scope: ph_th_hoh_scope).distinct.pluck(:client_id)

      #   literally_homeless += client_id if ph_th_hoh_client_ids.present?
      # end

      # literally_homeless.include?(client_id)
    end
  end
end
