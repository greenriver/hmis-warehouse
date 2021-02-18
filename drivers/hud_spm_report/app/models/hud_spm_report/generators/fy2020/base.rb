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
    include ArelHelper

    delegate :client_scope, to: :@generator

    def self.question_number
      raise 'Implement in your question report generator'.freeze
    end

    LOOKBACK_STOP_DATE = Date.iso8601('2012-10-01').freeze

    ES = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:es).flatten(1)
    SH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:sh).flatten(1)
    TH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:th).flatten(1)
    PH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:ph).flatten(1)

    ES_SH = ES + SH
    ES_SH_TH = ES + SH + TH
    ES_SH_PH = ES + SH + PH
    ES_SH_TH_PH = ES + SH + TH + PH
    PH_TH =  PH + TH

    SO = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:so).flatten(1)
    RRH = [13].freeze
    PH_PSH = [3, 9, 10].freeze

    private def universe
      add_clients unless clients_populated?
      @universe ||= @report.universe(self.class.question_number)
    end

    private def clients_populated?
      @report.report_cells.joins(universe_members: :spm_client).exists?
    end

    private def add_clients
      @debug = true

      shs_columns = {
        client_id: she_t[:client_id],
        enrollment_id: she_t[:id],
        date: shs_t[:date],
        project_type: she_t[:computed_project_type],
        first_date_in_program: she_t[:first_date_in_program],
        last_date_in_program: she_t[:last_date_in_program],
        DateToStreetESSH: e_t[:DateToStreetESSH],
        MoveInDate: e_t[:MoveInDate],
      }

      upsert_key = [:report_instance_id, :client_id, :data_source_id]
      upsert_cols = [
        :dob,
        :first_name,
        :last_name,
        :m1a_es_sh_days,
        :m1a_es_sh_th_days,
        :m1b_es_sh_ph_days,
        :m1b_es_sh_th_ph_days,
      ]

      client_scope.where(
        id: sh_enrollment_scope.select(:client_id),
      ).select(
        :id,
        :data_source_id,
        :DOB,
        :first_name,
        :last_name,
      ).find_in_batches do |batch|
        clients_by_id = batch.index_by(&:id)

        nights_for_batch = services_scope.where(
          client_id: clients_by_id.keys,
        ).order(client_id: :asc, date: :asc).pluck(*shs_columns.values).map do |row|
          shs_columns.keys.zip(row).to_h
        end

        # the enrollments scope does the preload to client etc so those instances

        pending_associations = nights_for_batch.group_by do |r|
          r.fetch(:client_id)
        end.map do |client_id, nights|
          client = clients_by_id.fetch(client_id)

          report_client = report_client_universe.new(
            report_instance_id: @report.id,
            client_id: client.id,
            data_source_id: client.data_source_id,
            dob: client.DOB,
            first_name: client.first_name,
            last_name: client.last_name,
            m1a_es_sh_days: calculate_days_homeless(nights, ES_SH, PH_TH, false, true),
            m1a_es_sh_th_days: calculate_days_homeless(nights, ES_SH_TH, PH, false, true),
            m1b_es_sh_ph_days: calculate_days_homeless(nights, ES_SH_PH, PH_TH, true, true),
            m1b_es_sh_th_ph_days: calculate_days_homeless(nights, ES_SH_TH_PH, PH, true, true),
          )

          [client, report_client]
        end.to_h

        # Import clients
        report_client_universe.import(
          pending_associations.values,
          on_duplicate_key_update: {
            conflict_target: upsert_key,
            columns: upsert_cols,
          },
        )
        # TODO: verify import result

        # Attach clients to relevant questions
        @report.build_for_questions.each do |question_number|
          universe_cell = @report.universe(question_number)
          universe_cell.add_universe_members(pending_associations)
        end
      end
    end

    private def report_client_universe
      HudSpmReport::Fy2020::SpmClient
    end

    private def sh_enrollment_scope
      scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.hud_project_type(ES_SH_TH_PH)
      scope = scope.open_between(
        start_date: @report.start_date,
        end_date: @report.end_date,
      ).with_service_between(
        start_date: @report.start_date,
        end_date: @report.end_date,
      )
      scope = scope.in_project(@report.project_ids) if @report.project_ids.present? # for consistency with client_scope
      scope
    end

    private def services_scope
      GrdaWarehouse::ServiceHistoryService.joins(
        :client,
        service_history_enrollment: :enrollment,
      ).merge(GrdaWarehouse::ServiceHistoryEnrollment.entry.hud_project_type(ES_SH_TH_PH))
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
    def calculate_days_homeless(all_nights, project_types, stop_project_types, include_pre_entry, consider_move_in_date)
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
        client_start_date = [client_end_date.to_date - 365.days, LOOKBACK_STOP_DATE].max
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
        client_start_date = [new_client_start_date.to_date, LOOKBACK_STOP_DATE].max
        # Rails.logger.info "Client's new start date: #{client_start_date}"

        # Remove any days outside of client_start_date and client_end_date
        # Rails.logger.info "Days homeless before limits #{homeless_days.count}"
        homeless_days.delete_if { |d| d.to_date < client_start_date.to_date || d.to_date > client_end_date.to_date }
        # Rails.logger.info "Days homeless after limits #{homeless_days.count}"
      end

      # if @debug
      #   info = {
      #     client_id: client.id,
      #     project_types: project_types,
      #     stop_project_types: stop_project_types,
      #     include_pre_entry: include_pre_entry,
      #     consider_move_in_date: consider_move_in_date,
      #     homeless_days: homeless_days.uniq.count,
      #   }
      #   puts info.inspect
      # end

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
          start_date = [entry[:DateToStreetESSH]&.to_date, LOOKBACK_STOP_DATE, entry[:DOB]&.to_date].compact.max
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
          stop_date = [entry[:MoveInDate], @report.end_date + 1.day].min
        elsif entry[:MoveInDate].blank?
          stop_date = begin
                          [entry[:last_date_in_program] - 1.day, @report.end_date].min
                        rescue StandardError
                          @report.end_date
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

      # puts "Processing #{dates.count} dates" if @debug
      days.each do |k, bed_nights|
        # puts "Looking at: #{bed_nights.count} bed nights on #{k}" if @debug
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
      # puts "Found: #{filtered_days.count}" if @debug
      # puts filtered_days.map { |day| [day.month, day.year] }.uniq.to_s if @debug
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
      true
      # TODO
      # # Literally HUD homeless
      # # Clients from ES, SO SH
      # es_so_sh_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
      #   hud_project_type(ES + SO + SH).
      #   open_between(start_date: @report.start_date - 1.day, end_date: @report.end_date).
      #   with_service_between(start_date: @report.start_date - 1.day, end_date: @report.end_date).
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
      #   open_between(start_date: @report.start_date - 1.day, end_date: @report.end_date).
      #   with_service_between(start_date: @report.start_date - 1.day, end_date: @report.end_date).
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
      #       open_between(start_date: @report.start_date - 1.day, end_date: @report.end_date).
      #       with_service_between(start_date: @report.start_date - 1.day, end_date: @report.end_date).
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
