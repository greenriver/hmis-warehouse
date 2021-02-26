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
    SO = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:so).flatten(1)

    PERMANENT_DESTINATIONS = [26, 11, 21, 3, 10, 28, 20, 19, 22, 23, 31, 33, 34].freeze
    TEMPORARY_DESTINATIONS = [1, 15, 6, 14, 7, 27, 16, 4, 29, 18, 12, 13, 5, 2, 25, 32].freeze

    ES_SH = ES + SH
    ES_SH_TH = ES + SH + TH
    ES_SH_PH = ES + SH + PH
    ES_SH_TH_PH = ES + SH + TH + PH
    ES_SH_TH_PH_SO = ES + SH + TH + PH + SO
    PH_TH =  PH + TH

    RRH = [13].freeze
    PH_PSH = [3, 9, 10].freeze

    UPSERT_KEY = [:report_instance_id, :client_id, :data_source_id].freeze

    private def universe
      # lazy pre-calculation of per-client version of the metrics
      unless clients_populated?
        add_m1_clients
        add_m2_clients
      end
      @universe ||= @report.universe(self.class.question_number)
    end

    private def clients_populated?
      @report.report_cells.joins(universe_members: :spm_client).exists?
    end

    # yield batches of the client scope indexed by `#id`
    # with only the necessary columns fetched/populated
    private def each_client_batch(scope)
      scope.select(
        :id,
        :PersonalID, # for debugging
        :data_source_id, # for add_universe_members
        :DOB, # for add_universe_members
        :first_name, # for add_universe_members
        :last_name, # for add_universe_members
      ).find_in_batches do |batch|
        clients_by_id = batch.index_by(&:id)
        yield clients_by_id
      end
    end

    # Attach `pending_associations` a Hash mapping Client =>  report_client_universe
    # to the Array|String `question_numbers`,
    # `updated_columns` are the columns to be upsert-ed into report_client_universe
    private def append_report_clients(question_numbers, pending_associations, updated_columns)
      report_client_universe.import(
        pending_associations.values,
        validate: false,
        on_duplicate_key_update: {
          conflict_target: UPSERT_KEY,
          columns: updated_columns,
        },
      )

      # Attach clients to relevant question(s)
      Array(question_numbers).each do |question_number|
        @report.universe(question_number).add_universe_members(pending_associations)
      end
    end

    private def add_m1_clients
      measure_one = 'Measure 1'
      return unless add_clients_for_question?(measure_one)

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

      updated_columns = [
        :dob,
        :first_name,
        :last_name,
        :m1a_es_sh_days,
        :m1a_es_sh_th_days,
        :m1b_es_sh_ph_days,
        :m1b_es_sh_th_ph_days,
        :m1_history,
      ]

      each_client_batch client_scope.where(
        id: active_enrollments_scope.select(:client_id),
      ) do |clients_by_id|
        # select all the necessary service history
        # for this batch of clients
        nights_for_batch = services_scope.where(
          client_id: clients_by_id.keys,
        ).order(client_id: :asc, date: :asc).pluck(*shs_columns.values).map do |row|
          shs_columns.keys.zip(row).to_h
        end

        # transform them into per client metrics
        pending_associations = nights_for_batch.group_by do |r|
          r.fetch(:client_id)
        end.map do |client_id, nights|
          nights = generate_non_service_dates(nights)

          # after resolving the non_service dates
          # roll this back up into something enrollment like
          # that shows how we classified each enrollment night
          m1_history = nights.group_by do |n|
            n[:enrollment_id]
          end.map do |enrollment_id, dates|
            {
              enrollment_id: enrollment_id,
              DateToStreetESSH: dates.first[:DateToStreetESSH]&.iso8601,
              first_date_in_program: dates.first[:first_date_in_program]&.iso8601,
              last_date_in_program: dates.first[:last_date_in_program]&.iso8601,
              MoveInDate: dates.first[:MoveInDate]&.iso8601,
              project_types: dates.map { |n| n[:project_type] }.uniq,
              pre_entry: date_ranges(dates.select { |n| n[:pre_entry] }),
              service: date_ranges(dates.reject { |n| n[:pre_move_in] || n[:pre_entry] }),
              pre_move_in: date_ranges(dates.select { |n| n[:pre_move_in] }),
            }
          end

          client = clients_by_id.fetch(client_id)

          # append_report_clients needs AR Instances
          report_client = report_client_universe.new(
            report_instance_id: @report.id,
            client_id: client.id,
            data_source_id: client.data_source_id,
            dob: client.DOB,
            first_name: client.first_name,
            last_name: client.last_name,
            m1_history: m1_history,
            m1a_es_sh_days: calculate_days_homeless(nights, ES_SH, PH_TH, false),
            m1a_es_sh_th_days: calculate_days_homeless(nights, ES_SH_TH, PH, false),
            m1b_es_sh_ph_days: calculate_days_homeless(nights, ES_SH_PH, PH_TH, true),
            m1b_es_sh_th_ph_days: calculate_days_homeless(nights, ES_SH_TH_PH, PH, true),
          )
          [client, report_client]
        end.to_h

        # Import clients
        append_report_clients measure_one, pending_associations, updated_columns
      end
    end

    private def add_clients_for_question?(question_number)
      @report.build_for_questions.include?(question_number)
    end

    private def add_m2_clients
      measure_two = 'Measure 2'
      return unless add_clients_for_question?(measure_two)

      project_types = (SO + ES + TH + SH + PH).freeze
      homeless_project_types = (ES +  SO + SH).freeze
      enrollment_columns = {
        client_id: :client_id,
        destination: :destination,
        date: :date,
        first_date_in_program: :first_date_in_program,
        last_date_in_program: :last_date_in_program,
        project_type: :computed_project_type,
        project_id: :project_id,
        project_name: :project_name,
        household_id: :household_id,
      }.freeze

      updated_columns = [
        :dob,
        :first_name,
        :last_name,
        :m2_exit_from_project_type,
        :m2_exit_to_destination,
        :m2_reentry_days,
        :m2_history,
      ].freeze

      # 1. Select clients across all projects in the COC of the relevant type (SO, ES, TH, SH, PH) with
      # a project exit date 2 years prior to the report date range, going back no further than the [Lookback Stop Date].
      each_client_batch client_scope.where(id: exits_scope.select(:client_id)) do |clients_by_id|
        m2_clients = {}

        exits_by_client_id = exits_for_batch(clients_by_id.keys, enrollment_columns).group_by do |e|
          e[:client_id]
        end.freeze
        entries_by_client_id = entries_for_batch(clients_by_id.keys, enrollment_columns).group_by do |e|
          e[:client_id]
        end.freeze

        exits_by_client_id.each do |client_id, client_exits|
          # 2. Of the universe of project exits, determine each client’s
          # earliest [project exit date] where the [destination] was permanent housing.
          p_exit = client_exits.detect do |client_exit|
            # inherit destination from HoH if age <= 17 and destination not collected
            destination = destination_for(project_types, client_exit[:client_id], client_exit[:household_id])
            client_exit[:destination] = destination if destination.present?

            permanent_destination?(client_exit[:destination])
          end

          next unless p_exit

          # 3. Using data from step 2, report the distinct number of clients who exited to permanent housing destinations
          # according to the project type associated with the client’s earliest applicable exit (cells B2-B6).

          client = clients_by_id.fetch(client_id)
          m2_client = report_client_universe.new(
            report_instance_id: @report.id,
            client_id: client_id,
            data_source_id: client.data_source_id,
            dob: client.DOB,
            first_name: client.first_name,
            last_name: client.last_name,
          )

          # 4. Using data from step 2, report the distinct number of clients who exited to permanent housing destinations
          # without regard to the project type associated with the client’s earliest applicable exit (cell B7).
          m2_client.m2_exit_from_project_type = p_exit[:project_type]
          m2_client.m2_exit_to_destination = p_exit[:destination]

          # 5. Using data from step 2, scan forward in time beginning from each client’s [project exit date]
          # with a permanent housing destination to see if the client has a project start into a project
          # indicating the client is now homeless again.

          # 5.a && 5.d
          reentries = entries_by_client_id[client_id].select do |e|
            (e[:first_date_in_program] >= p_exit[:last_date_in_program]) && (e[:first_date_in_program] <= @report.end_date)
          end

          # this is our first exit from PR
          previous_exit_from_ph = p_exit[:last_date_in_program]
          reentry = reentries.detect do |entry|
            entry_date = entry[:first_date_in_program]

            found = if entry[:project_type].in?(homeless_project_types)
              # homeless projects...
              true
            elsif entry[:project_type].in?(TH)
              # 5.b When scanning for the client’s reappearance in a transitional housing project,
              # the [project start date] must be more than 14 days after the client’s original
              # [project exit date] from step 2 to be considered a return to homelessness.
              (entry_date - p_exit[:last_date_in_program]).to_i > 14
            elsif entry[:project_type].in?(PH)
              # 5.c When scanning for the client’s reappearance in a
              # permanent housing project, the [project start date] must be more than
              # 14 days after the client’s original [project exit date] from step 2 to
              # be considered a return to homelessness
              # AND must also be more than 14
              # days after any other permanent housing or transitional housing
              # [project exit date] for the same client. This prevents accidentally
              # counting clients who transition from transitional to permanent
              # housing, or from one CoC permanent housing program to another PH
              # project
              (entry_date - previous_exit_from_ph).to_i > 14
            end

            previous_exit_from_ph = entry[:last_date_in_program] if entry[:project_type].in?(PH + TH)

            found
          end

          # 6. Use the [project start date] found in step 5 to calculate the number of days between the
          # client’s [project exit date] from step 2 until the client was identified
          # as homeless again.
          m2_client.m2_reentry_days = if reentry
            reentry[:first_date_in_program] - p_exit[:last_date_in_program]
          else
            0
          end

          # Audit of exit/entries we considered
          m2_client.m2_history = {
            exit: p_exit,
            reentries: reentries,
          }

          m2_clients[client] = m2_client
        end

        # Steps 7 - 9 are handled in MeasureTwo#run_question!
        append_report_clients measure_two, m2_clients, updated_columns
      end
    end

    private def exits_for_batch(client_ids, columns)
      exits_scope.where(
        client_id: client_ids,
      ).order(client_id: :asc, last_date_in_program: :asc).
        select(*columns.values).
        pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end
    end

    private def add_filters(scope:)
      # scope = scope.in_project(@report.project_ids) if @report.project_ids.present?

      scope
    end

    private def destination_for(project_types, client_id, household_id)
      children_without_destination(project_types)[[client_id, household_id]]
    end

    private def children_without_destination(project_types)
      # TODO: batch this... right now it loads ALL enrollments with service during the report range
      # 99 = Not collected
      destination_not_collected = [99]

      @child_ids ||= {}
      @child_ids[project_types] ||= begin
        child_candidates_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
          hud_project_type(project_types).
          open_between(start_date: @report.start_date - 1.day, end_date: @report.end_date).
          with_service_between(start_date: @report.start_date - 1.day, end_date: @report.end_date).
          joins(:enrollment, :client).
          where(
            she_t[:destination].in(destination_not_collected).or(she_t[:destination].eq(nil)),
            c_t[:DOB].not_eq(nil).and(c_t[:DOB].lteq(@report.start_date - 17.years)),
          ).
          distinct.
          select(:client_id)

        scope = add_filters(scope: child_candidates_scope)

        child_candidates = scope.
          pluck(
            :client_id,
            c_t[:DOB],
            e_t[:EntryDate],
            :age,
            :head_of_household_id,
            :household_id,
          )

        child_id_to_destination = {}
        child_candidates.each do |(client_id, dob, entry_date, age, hoh_id, household_id)|
          age = age_for_report dob: dob, entry_date: entry_date, age: age
          child_id_to_destination[[client_id, household_id]] = hoh_destination_for(project_types, hoh_id, household_id) if age.present? && age <= 17
        end
        child_id_to_destination
      end
    end

    def hoh_destinations(project_types)
      # TODO: batch this... right now it loads ALL enrollments with service during the report range
      @hoh_destinations ||= {}
      @hoh_destinations[project_types] ||= begin
        GrdaWarehouse::ServiceHistoryEnrollment.exit.
          hud_project_type(project_types).
          open_between(start_date: @report.start_date - 1.day, end_date: @report.end_date).
          with_service_between(start_date: @report.start_date - 1.day, end_date: @report.end_date).
          joins(:client).
          where(she_t[:head_of_household].eq(true)).
          distinct.
          pluck(:head_of_household_id, :destination, :household_id).
          map do |(hoh_id, destination, household_id)|
            [[hoh_id, household_id], destination]
          end.to_h
      end
    end

    def hoh_destination_for(project_types, client_id, household_id)
      hoh_destinations(project_types)[[client_id, household_id]]
    end

    # return an array of date ranges
    private def date_ranges(nights)
      nights.map { |n| n[:date] }.slice_when do |i, j|
        (j - i > 1)
      end.map do |span|
        days = span.last - span.first + 1
        "#{span.first.iso8601}/P#{days.to_i}D"
      end.presence
    end

    private def logger
      @report.logger
    end

    private def prepare_table(table_name, rows, cols)
      @report.answer(question: table_name).update(
        metadata: {
          header_row: [''] + cols.values,
          row_labels: rows.values,
          first_column: cols.keys.first,
          last_column: cols.keys.last,
          first_row: rows.keys.first,
          last_row: rows.keys.last,
        },
      )
    end

    private def report_client_universe
      HudSpmReport::Fy2020::SpmClient
    end

    private def t
      report_client_universe.arel_table
    end

    # passed an table_name and Array of [cell_name, member_condition_arel] tuples
    private def handle_clause_based_cells(table_name, cell_specs)
      cell_specs.each do |cell, member_scope, summary_value|
        answer = @report.answer(question: table_name, cell: cell)
        answer.add_members(member_scope)
        answer.update(summary: summary_value)
      end
    end

    private def median(scope, field)
      scope.pluck(Arel.sql("percentile_cont(0.5) WITHIN GROUP (ORDER BY #{field})")).first
    end

    private def services_scope
      GrdaWarehouse::ServiceHistoryService.joins(
        :client,
        service_history_enrollment: :enrollment,
      ).merge(GrdaWarehouse::ServiceHistoryEnrollment.entry.hud_project_type(ES_SH_TH_PH))
    end

    private def active_enrollments_scope
      scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.hud_project_type(ES_SH_TH_PH)
      scope = scope.open_between(
        start_date: @report.start_date,
        end_date: @report.end_date,
      ).with_service_between(
        start_date: @report.start_date,
        end_date: @report.end_date,
      )
      add_filters(scope: scope)
    end

    private def m2_lookback
      [LOOKBACK_STOP_DATE, @report.start_date - 730.days].max .. (@report.end_date - 730.days)
    end

    private def m2_lookforward
      [LOOKBACK_STOP_DATE, @report.start_date - 730.days].max .. @report.end_date
    end

    private def exits_scope
      GrdaWarehouse::ServiceHistoryEnrollment.exit.
        joins(:project).hud_project_type(SO + ES + TH + SH + PH).
        where(last_date_in_program: m2_lookback)
    end

    private def entries_for_batch(client_ids, columns)
      GrdaWarehouse::ServiceHistoryEnrollment.entry.
        joins(:project).hud_project_type(SO + ES + TH + SH + PH).
        where(client_id: client_ids).
        where(first_date_in_program: m2_lookforward).
        order(client_id: :asc, last_date_in_program: :asc).
        pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end
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
    def calculate_days_homeless(all_nights, project_types, stop_project_types, include_pre_entry)
      homeless_days = filter_days_for_homelessness(
        all_nights,
        project_types,
        stop_project_types,
        include_pre_entry,
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

      homeless_days.uniq.count
    end

    # The SPM reports need to consider nights that are not recorded
    # directly as service_nights. We are looking at two time-frames:
    #
    #  pre_entry:
    #    A night between the self-reported DateToStreetESSH (Question 3.917.3) clamped
    #    to be on or after LOOKBACK_STOP_DATE and DOB and before first_date_in_program
    #  pre_move_in:
    #    A night between am entry into a PH program and the move-in date
    #
    def generate_non_service_dates(nights)
      # Add fake records for every day between DateToStreetESSH and first_date_in_program.

      # force these days to be ES since that's included in all 1b measures
      non_service_project_type = 1

      # Find the first entry for each enrollment based on unique project type and first_date in program
      entries = nights.index_by do |m|
        [m[:project_type], m[:first_date_in_program]]
      end

      entries.each do |_, entry|
        next unless literally_homeless?(entry)

        # 3.917.3 - add any days prior to project entry
        if entry[:DateToStreetESSH].present? && entry[:first_date_in_program] > entry[:DateToStreetESSH]
          start_date = [entry[:DateToStreetESSH]&.to_date, LOOKBACK_STOP_DATE, entry[:DOB]&.to_date].compact.max
          new_nights = (start_date..entry[:first_date_in_program]).map do |date|
            {
              date: date,
              pre_entry: true,
              project_type: non_service_project_type,
              enrollment_id: entry[:enrollment_id],
              first_date_in_program: entry[:first_date_in_program],
              DateToStreetESSH: entry[:DateToStreetESSH],
              MoveInDate: entry[:MoveInDate],
            }
          end
          nights += new_nights
        end

        # move in date adjustments - These dates will exist as PH, but we want to make sure they get
        # included in the acceptable project types.  Convert the project type of any days pre-move-in
        # for PH to a project type we will be counting
        next unless PH.include?(entry[:project_type])

        start_date = [entry[:first_date_in_program].to_date, entry[:DOB]&.to_date].compact.max
        stop_date = if entry[:MoveInDate].present? && entry[:MoveInDate] > entry[:first_date_in_program]
          [entry[:MoveInDate], @report.end_date + 1.day].min
        elsif entry[:MoveInDate].blank?
          begin
            [entry[:last_date_in_program] - 1.day, @report.end_date].min
          rescue StandardError
            @report.end_date
          end
        end
        next unless stop_date.present?

        date_range = (start_date...stop_date)
        date_range.each do |date|
          matching_night = nights.detect do |night|
            night[:enrollment_id] == entry[:enrollment_id] && night[:date] == date
          end
          if matching_night.present?
            # convert date to homeless night
            matching_night[:project_type] = non_service_project_type
            matching_night[:pre_move_in] = true
          else
            # add a pre_move_in "homeless night"
            nights << {
              enrollment_id: entry[:enrollment_id],
              date: date,
              project_type: non_service_project_type,
              pre_move_in: true,
              first_date_in_program: entry[:first_date_in_program],
              last_date_in_program: entry[:last_date_in_program],
              DateToStreetESSH: entry[:DateToStreetESSH],
              MoveInDate: entry[:MoveInDate],
            }
          end
        end
      end

      # re-sort them
      nights.sort_by { |m| m[:date] }
    end

    # Applies logic described in the Programming Specifications to limit the entries
    # for each day to one, and only those that should be considered based on the project types
    def filter_days_for_homelessness(dates, _project_types, stop_project_types, include_pre_entry)
      consider_move_in_dates = true

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
          # ignore pre_entry/move_in nights if the metric wants us to

          next if night[:pre_entry] && !include_pre_entry
          next if night[:pre_move_in] && !include_pre_entry

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

    private def permanent_destination?(dest)
      PERMANENT_DESTINATIONS.include?(dest)
    end

    private def literally_homeless?(_night)
      true
      # FIXME
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
