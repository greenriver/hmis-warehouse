###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Generates the HUD SPM Report Data according to:
# System Performance Measures Programming Specifications Version 3.1
# October 2019 Office of Community Planning and Development, HUD
#
# Downloaded Jan 2021 from
# https://files.hudexchange.info/resources/documents/System-Performance-Measures-HMIS-Programming-Specifications.pdf

module HudSpmReport::Generators::Fy2020
  class Base < ::HudReports::QuestionBase
    include Filter::FilterScopes
    include ArelHelper

    delegate :client_scope, to: :@generator

    def self.question_number
      raise 'Implement in your question report generator'.freeze
    end

    def self.she_household_column
      cl(she_t[:household_id], ct(she_t[:id], '*HH'))
    end

    def she_household_column
      self.class.she_household_column
    end

    LOOKBACK_STOP_DATE = Date.iso8601('2012-10-01').freeze

    ES = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:es).flatten(1).freeze
    SH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:sh).flatten(1).freeze
    TH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:th).flatten(1).freeze
    PH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:ph).flatten(1).freeze
    SO = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:so).flatten(1).freeze

    PERMANENT_DESTINATIONS = [26, 11, 21, 3, 10, 28, 20, 19, 22, 23, 31, 33, 34].freeze
    PERMANENT_DESTINATIONS_OR_STAYER = (PERMANENT_DESTINATIONS + [0]).freeze

    HOMELESS_LIVING_SITUATIONS = [16, 1, 18].freeze
    INSTITUTIONAL_LIVING_SITUATIONS = [15, 6, 7, 25, 4, 5].freeze
    HOUSED_LIVING_SITUATIONS = [29, 14, 2, 32, 36, 35, 28, 19, 3, 31, 33, 34, 10, 20, 21, 11, 8, 9, 99].freeze

    ES_SH = ES + SH
    ES_SH_TH = ES + SH + TH
    ES_SH_PH = ES + SH + PH
    ES_SH_TH_PH = ES + SH + TH + PH
    ES_SH_TH_PH_SO = ES + SH + TH + PH + SO
    PH_TH =  PH + TH

    RRH = [13].freeze
    PH_PSH = [3, 9, 10].freeze
    PSH_ONLY = [3].freeze
    OPH = [9, 10].freeze

    UPSERT_KEY = [:report_instance_id, :client_id, :data_source_id].freeze

    CHANGE_TABLE_COLS = {
      'B' => 'Previous FY',
      'C' => 'Current FY',
      'D' => 'Difference',
    }.freeze

    SHE_COLUMNS = {
      client_id: :client_id,
      destination: :destination,
      date: :date,
      first_date_in_program: :first_date_in_program,
      last_date_in_program: :last_date_in_program,
      project_type: :computed_project_type,
      project_id: p_t[:id],
      project_name: :project_name,
      household_id: she_household_column,
      housing_status_at_entry: :housing_status_at_entry,
      housing_status_at_exit: :housing_status_at_exit,
      MoveInDate: :move_in_date,
      head_of_household: :head_of_household,
    }.freeze

    # HudReports::UniverseMember scope to use for this measure
    # Will calculate all requested "build_for_questions" universes
    # if that has not already been done and then return
    # those need for the current question as a memoized query
    private def universe
      unless clients_populated?
        # Since each question *might* involve different clients
        # and can be run independently we have in the past had pipelines for each.
        # There is a bunch of overlap however, many of the measures are interested
        # in clients active in a similar subset of projects during or within the
        # past few years.  A nice performance re-factor would be to pull all possible
        # enrollments for all measures as one database scan and then link them to
        # questions as needed.
        add_m1_clients
        add_m2_clients
        add_m3_clients
        add_m4_clients
        add_m5_clients
        add_m6_clients
        add_m7_clients
      end
      @universe ||= @report.universe(self.class.question_number)
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

    # passed an table_name and Array of [cell_name, member_scope, summary_value] tuples
    private def handle_clause_based_cells(table_name, cell_specs)
      cell_specs.each do |cell, member_scope, summary_value|
        answer = @report.answer(question: table_name, cell: cell)
        answer.add_members(member_scope) if member_scope
        answer.update(summary: summary_value)
      end
    end

    # yield batches of the client scope indexed by `#id`
    # with only the necessary columns fetched/populated
    private def each_client_batch(scope, start_date: @report.start_date, end_date: @report.end_date)
      client_scope(start_date: start_date, end_date: end_date).where(id: scope.select(:client_id)).select(
        :id,
        :PersonalID, # for debugging
        :SSN, # for debugging
        :data_source_id, # for add_universe_members
        :DOB, # for add_universe_members
        :first_name, # for add_universe_members
        :last_name, # for add_universe_members
        :VeteranStatus,
      ).find_in_batches do |batch|
        clients_by_id = batch.index_by(&:id)
        yield clients_by_id
      end
    end

    private def process_scope_by_client(measure_name, scope, columns)
      each_client_batch(scope) do |clients_by_id|
        hashes = pluck_to_hash(
          columns,
          scope.where(client_id: clients_by_id.keys).order(client_id: :asc),
        )
        updated_columns = Set.new
        pending_associations = {}

        hashes.group_by do |r|
          r.fetch(:client_id)
        end.each do |client_id, rows|
          client = clients_by_id.fetch(client_id)
          if (data = yield(client, rows))
            updated_columns += data.keys
            pending_associations[client] = build_report_client(client, data)
          end
        end
        append_report_clients(measure_name, pending_associations, updated_columns.to_a)
      end
    end

    private def age_for_report(dob:, entry_date:, age:)
      # Age should be calculated at report start or enrollment start, whichever is greater
      return age if dob.blank?
      return age if entry_date.blank?

      entry_date = entry_date.to_date
      date = if entry_date > @report.start_date
        entry_date
      else
        @report.start_date
      end

      GrdaWarehouse::Hud::Client.age(dob: dob, date: date)
    end

    private def build_report_client(client, data = {})
      raise ArgmentError, 'wrong client type' unless client.is_a? ::GrdaWarehouse::Hud::Client
      raise ArgmentError, 'data needs to be Hash-like' unless data.respond_to?(:merge)

      data_lab_public_id = if client.SSN.blank?
        nil
      else
        "#{client.first_name}#{client.SSN[-4..]}"
      end
      report_client_universe.new data.merge(
        report_instance_id: @report.id,
        client_id: client.id,
        data_source_id: client.data_source_id,
        dob: client.DOB,
        personal_id: client.PersonalID, # for debugging
        data_lab_public_id: data_lab_public_id,
        first_name: client.first_name,
        last_name: client.last_name,
      )
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

    private def filter
      # this needs to be re-hydrated from the data stored in report
      @filter ||= ::Filters::HudFilterBase.new @report.options.merge(user_id: @report.user_id)
    end

    # Add report filters to the scope
    private def add_filters(scope)
      project_ids = filter.effective_project_ids
      scope = scope.joins(:project).where(p_t[:id].in(project_ids)) if project_ids.any?

      scope = filter_for_cocs(scope)
      scope = filter_for_veteran_status(scope)
      scope = filter_for_household_type(scope)
      scope = filter_for_head_of_household(scope)
      scope = filter_for_age(scope)
      scope = filter_for_gender(scope)
      scope = filter_for_race(scope)
      scope = filter_for_ethnicity(scope)
      scope = filter_for_sub_population(scope)
      # Some additional filtering that isn't exposed in the UI but
      # is used for the homeless summary report
      scope = filter_for_dv_currently_fleeing(scope)
      scope = filter_for_veteran_status(scope)
      scope = filter_for_indefinite_disabilities(scope)
      scope = filter_for_rrh_move_in(scope)
      scope = filter_for_psh_move_in(scope)
      scope = filter_for_first_time_homeless_in_past_two_years(scope)
      scope = filter_for_returned_to_homelessness_from_permanent_destination(scope)

      scope
    end

    # Report a percentage using the expected rounding
    # and handling of zero denominator etc.
    private def report_precentage(numerator, denominator)
      return 0 if denominator.zero?

      (numerator * 100.0 / denominator).round(2)
    end

    private def add_clients_for_question?(question_number)
      @report.build_for_questions.include?(question_number)
    end

    private def clients_populated?
      @report.report_cells.joins(universe_members: :spm_client).exists?
    end

    private def report_client_universe
      HudSpmReport::Fy2020::SpmClient
    end

    # handy alias for the report_client_universe table
    private def t
      report_client_universe.arel_table
    end

    private def median(scope, field)
      scope.pluck(Arel.sql("percentile_cont(0.5) WITHIN GROUP (ORDER BY #{field})")).first
    end

    private def add_m1_clients
      measure_one = 'Measure 1'
      return unless add_clients_for_question?(measure_one)

      shs_columns = {
        client_id: shs_t[:client_id],
        enrollment_id: shs_t[:service_history_enrollment_id],
        date: shs_t[:date],
        project_type: shs_t[:project_type],
        project_id: p_t[:id],
        first_date_in_program: she_t[:first_date_in_program],
        last_date_in_program: she_t[:last_date_in_program],
        HouseholdID: e_t[:HouseholdID],
        DateToStreetESSH: e_t[:DateToStreetESSH],
        LivingSituation: e_t[:LivingSituation],
        LOSUnderThreshold: e_t[:LOSUnderThreshold], # [Did you stay less than 90 days?]
        PreviousStreetESSH: e_t[:PreviousStreetESSH], # [On the night before did you stay on the streets, ES or SH]
        MoveInDate: she_t[:move_in_date],
        age: shs_t[:age],
        head_of_household: she_t[:head_of_household],
        data_source_id: e_t[:data_source_id],
      }

      updated_columns = [
        :m1a_es_sh_days,
        :m1a_es_sh_th_days,
        :m1b_es_sh_ph_days,
        :m1b_es_sh_th_ph_days,
        :m1_history,
      ]

      each_client_batch(active_enrollments_scope) do |clients_by_id|
        # select all the necessary service history
        # for this batch of clients
        nights_for_batch = pluck_to_hash(
          shs_columns,
          services_scope.
            where(shs_t[:date].between(LOOKBACK_STOP_DATE..@report.end_date)).
            where(client_id: clients_by_id.keys).
            order(client_id: :asc, date: :asc),
        ).uniq

        # transform them into per client metrics
        pending_associations = nights_for_batch.group_by do |r|
          r.fetch(:client_id)
        end.map do |client_id, nights|
          client = clients_by_id.fetch(client_id)
          # note if the night is housed and if the enrollment is literally homeless
          nights.each do |night|
            if PH.include?(night[:project_type])
              night[:housed] = night[:MoveInDate].present? && night[:MoveInDate] <= night[:date]
              night[:pre_move_in] = night[:MoveInDate].blank? || night[:MoveInDate] > night[:date]
            else
              night[:housed] = false
              night[:pre_move_in] = false
            end
            night[:literally_homeless] = literally_homeless?(night)
          end
          nights = generate_non_service_dates(nights)

          # after resolving the non_service dates
          # roll this back up into something enrollment like
          # that shows how we classified each enrollment night
          m1_history = nights.group_by do |n|
            n[:enrollment_id]
          end.map do |enrollment_id, dates|
            first_date = dates.first
            {
              enrollment_id: enrollment_id,
              project_id: first_date[:project_id],
              DateToStreetESSH: first_date[:DateToStreetESSH]&.iso8601,
              first_date_in_program: first_date[:first_date_in_program]&.iso8601,
              last_date_in_program: first_date[:last_date_in_program]&.iso8601,
              MoveInDate: first_date[:MoveInDate]&.iso8601,
              LivingSituation: first_date[:LivingSituation],
              LOSUnderThreshold: first_date[:LOSUnderThreshold],
              PreviousStreetESSH: first_date[:PreviousStreetESSH],
              HouseholdID: first_date[:HouseholdID],
              project_types: dates.map { |n| n[:project_type] }.uniq,
              pre_entry: date_ranges(dates.select { |n| n[:pre_entry] }),
              service: date_ranges(dates.reject { |n| n[:pre_move_in] || n[:pre_entry] }),
              pre_move_in: date_ranges(dates.select { |n| n[:pre_move_in] }),
              head_of_household: first_date[:head_of_household],
              data_source_id: first_date[:data_source_id],
            }
          end

          # puts "processing #{client.first_name} #{client.last_name}"
          report_client = build_report_client(
            client,
            m1_history: { enrollments: m1_history },
            m1a_es_sh_days: calculate_valid_days_in_project_type(nights.dup, project_types: ES_SH, line: :m1a1),
            m1a_es_sh_th_days: calculate_valid_days_in_project_type(nights.dup, project_types: ES_SH_TH, line: :m1a2),
            m1b_es_sh_ph_days: calculate_valid_days_in_project_type(nights.dup, project_types: ES_SH_PH, line: :m1b1),
            m1b_es_sh_th_ph_days: calculate_valid_days_in_project_type(nights.dup, project_types: ES_SH_TH_PH, line: :m1b2, debug: false),
            m1_reporting_age: age_for_report(dob: client.DOB, entry_date: m1_history.last[:last_date_in_program], age: m1_history.first[:age]),
            veteran: client.veteran?,
            m1_head_of_household: m1_history.last[:head_of_household] || false,
          )
          [client, report_client]
        end.to_h

        # Import clients
        append_report_clients(measure_one, pending_associations, updated_columns)
      end
    end

    private def add_m2_clients
      # 1. Select clients across all projects in the COC of the relevant type (SO, ES, TH, SH, PH) with
      # a project exit date 2 years prior to the report date range, going back no further than the [Lookback Stop Date].
      add_exiting_clients('Measure 2', exits_scope, :m2, ES_SH_TH_PH_SO.freeze)
    end

    private def add_m3_clients
      measure_three = 'Measure 3'
      return unless add_clients_for_question?(measure_three)

      process_scope_by_client(measure_three, active_enrollments_scope.hud_project_type(ES_SH_TH), SHE_COLUMNS) do |client, enrollments|
        {
          m3_active_project_types: enrollments.map { |e| e[:project_type] }.uniq,
          m3_history: { enrollments: enrollments.map { |e| { project_id: e[:project_id] } } },
          m3_project_id: enrollments.last[:project_id],
          m3_reporting_age: age_for_report(dob: client.DOB, entry_date: enrollments.last[:last_date_in_program], age: enrollments.first[:age]),
          veteran: client.veteran?,
          m3_head_of_household: enrollments.last[:head_of_household] || false,
        }
      end
    end

    private def add_m4_clients
      measure_four = 'Measure 4'
      return unless add_clients_for_question?(measure_four)

      stay_columns = {
        enrollment_id: she_t[:id],
        data_source_id: she_t[:data_source_id],
        client_id: she_t[:client_id],
        DOB: c_t[:DOB],
        PersonalID: c_t[:PersonalID],
        SSN: c_t[:SSN],
        first_date_in_program: she_t[:first_date_in_program],
        last_date_in_program: she_t[:last_date_in_program],
        project_id: p_t[:id],
        project_name: she_t[:project_name],
        enrollment_group_id: she_t[:enrollment_group_id],
        project_tracking_method: she_t[:project_tracking_method],
        funder_id: f_t[:id],
        funding_source: f_t[:Funder],
        funder_start_date: f_t[:StartDate],
        funder_end_date: f_t[:EndDate],
        GrantID: f_t[:GrantID],
      }.freeze

      # 2. For metrics 4.1, 4.2 and 4.3 (adult system stayers), determine the
      # relevant project stay and Income and Sources records attached to that
      # stay for each client.  # a. Select each client’s project stays in
      # which the client was active on the [report end date]

      # a. Select each client’s project stays in which the client was active on
      # the [report end date] in any of the relevant projects as determined in step 1.
      process_scope_by_client(measure_four, m4_stayers_scope, stay_columns) do |client, enrollments|
        # b. For each client, remove any stays where the [length of stay] is < 365 days.
        # Use the calculation of [length of stay] as described in the HMIS Reporting
        # Glossary, including time in the project prior to the [report start date].
        long_enrollments = enrollments.select do |e|
          night_count = if e[:project_tracking_method] == 3
            es_nbn_length_of_stay_for(e[:client_id], e[:enrollment_id])
          else
            # exiting on the same day is a stay of 0 days
            ((e[:last_date_in_program] || @report.end_date) - e[:first_date_in_program])
          end

          # NOTE: this was > 365 in FY2019 but the spec says "at least", so converted eo >=
          night_count >= 365
        end

        # c. For each client, remove all but the stay with the latest [project start date].
        final_stay = long_enrollments.max_by { |e| e[:first_date_in_program] }
        next unless final_stay

        # d. For each client, remove the stay if the client’s age (as calculated according to
        #    then HMIS Reporting Glossary) is less than 18.
        final_stay[:age] = age_for_report(dob: final_stay[:DOB], entry_date: final_stay[:first_date_in_program], age: final_stay[:age])
        next unless final_stay[:age].blank? || final_stay[:age] >= 18

        # We only consider clients who have an initial income report
        # e. The application of these filters will result in a dataset of
        # project stays with no more than one stay per client. It is expected
        # that some clients initially selected in step a. may have been removed
        # completely from the dataset and from the entire measure.

        final_stay = add_stayer_income(final_stay)

        # h. Clients who are completely missing their earlier data point, i.e.
        # clients missing Income and Sources at project start, are excluded
        # entirely from the universe of clients. Report the total number of
        # system stayers, excluding these clients, in cell C2.

        # i. Clients who have been in the project 365 or more days but who are
        # completely missing their later data point are included in the universe
        # of clients (cell C2) but cannot be counted as having an increase in
        # any type of income (cell C3). next unless final_stay
        next unless final_stay

        {
          m4_stayer: true,
          m4_history: { enrollments: enrollments },
          m4_project_id: final_stay[:project_id],
          m4_latest_income: final_stay[:latest_income],
          m4_latest_earned_income: final_stay[:latest_earned_income],
          m4_latest_non_earned_income: final_stay[:latest_non_earned_income],
          m4_earliest_income: final_stay[:earliest_income],
          m4_earliest_earned_income: final_stay[:earliest_earned_income],
          m4_earliest_non_earned_income: final_stay[:earliest_non_earned_income],
          m4_reporting_age: final_stay[:age],
          veteran: client.veteran?,
          m4_head_of_household: final_stay[:head_of_household] || false,
        }
      end

      process_scope_by_client(measure_four, m4_leavers_scope, stay_columns) do |client, enrollments|
        # c. For each client, remove all but the stay with the latest [project start date].
        final_stay = enrollments.max_by { |e| e[:first_date_in_program] }
        next unless final_stay

        # d. For each client, remove the stay if the client’s age (as calculated according to
        #    then HMIS Reporting Glossary) is less than 18.
        final_stay[:age] = age_for_report(dob: final_stay[:DOB], entry_date: final_stay[:first_date_in_program], age: final_stay[:age])
        next unless final_stay[:age].blank? || final_stay[:age] >= 18

        # d. Similar to the filtering performed on system stayers, these filters
        # will result in a dataset of project stays with no more than one stay
        # per client.
        final_stay = add_leaver_income(final_stay)
        next unless final_stay

        {
          m4_stayer: false,
          m4_history: enrollments,
          m4_project_id: final_stay[:project_id],
          m4_latest_income: final_stay[:latest_income],
          m4_latest_earned_income: final_stay[:latest_earned_income],
          m4_latest_non_earned_income: final_stay[:latest_non_earned_income],
          m4_earliest_income: final_stay[:earliest_income],
          m4_earliest_earned_income: final_stay[:earliest_earned_income],
          m4_earliest_non_earned_income: final_stay[:earliest_non_earned_income],
          m4_reporting_age: final_stay[:age],
          veteran: client.veteran?,
          m4_head_of_household: final_stay[:head_of_household] || false,
        }
      end
    end

    private def es_nbn_length_of_stay_for(client_id, enrollment_id)
      @es_nbn_length_of_stay_for ||= services_scope.joins(service_history_enrollment: :project).merge(GrdaWarehouse::Hud::Project.night_by_night).distinct.group(:client_id, :service_history_enrollment_id).count(:date)
      @es_nbn_length_of_stay_for[client_id, enrollment_id]
    end

    private def add_m5_clients
      measure_five = 'Measure 5'
      # This could be merged with M3
      return unless add_clients_for_question?(measure_five)

      process_scope_by_client(measure_five, m5_enrollments_scope, SHE_COLUMNS) do |client, client_enrollments|
        # 1. Select clients entering any of the applicable project types in the report date range
        active_enrollments = client_enrollments.select do |e|
          (
            e[:project_type].in? ES_SH_TH_PH
          ) && (
            e[:first_date_in_program] >= @report.start_date && e[:first_date_in_program] <= @report.end_date
          )
        end
        # We might not have any since we are fetching all clients with recent history
        next if active_enrollments.none?

        # 2. Report the total distinct number of clients in cell C2.
        # (will happen later)

        # 3. Of the project stay records selected in step 1, get the earliest [project start date]
        # for each client. This becomes the [client start date].
        client_start = active_enrollments.map { |e| e[:first_date_in_program] }.min

        # 4. Working backwards in time using data from ES, SH, TH and PH projects, determine if the
        # client was active in any project on or prior to the [client start date].
        # Look backwards up to ( [project start date] - 730 days ) or the [Lookback Stop Date], whichever is later.
        # a. In the case of metric 5.1, the projects scanned for client presence
        # is different from the projects used in the initial selection of data
        # in step 1. For metric 5.2, the projects scanned for client presence is
        # the same.
        # b. Search for project stays where [project start date] < [client start
        # date] and [project exit date] is null or [project exit date] >=
        # greater of ( [Lookback Stop Date] and ( [client start date] – 730 days ) )
        # c. If a match is found, report the client in cell C3. Report the
        # client no more than once regardless of how many prior project stays
        # were found for the client.
        last_date_cutoff = [client_start - 730.days, LOOKBACK_STOP_DATE].max
        prior_enrollments = client_enrollments.select do |e|
          (
            e[:project_type].in? ES_SH_TH_PH
          ) && (
            e[:first_date_in_program] < client_start &&
            (e[:last_date_in_program].nil? || e[:last_date_in_program] >= last_date_cutoff)
          )
        end

        # 5. Because each client may be counted no more than once in cells
        # C2 and C3, cell C4 is a simple formula indicated in the table shell above. (happens later)
        {
          m5_active_project_types: active_enrollments.map { |e| e[:project_type] }.uniq,
          m5_recent_project_types: prior_enrollments.map { |e| e[:project_type] }.uniq,
          m5_history: { prior_enrollments: prior_enrollments, active_enrollments: active_enrollments },
          m5_project_id: active_enrollments.last[:project_id],
          m5_reporting_age: client_enrollments.last[:age],
          veteran: client.veteran?,
          m5_head_of_household: active_enrollments.last[:head_of_household] || false,
        }
      end
    end

    private def add_m6_clients
      # Re-use the same programming instructions from Measures 2 and 7 as described above.
      # The universe of relevant projects varies for this measure as this measure is
      # required only for CoC-program-funded projects in communities approved by HUD
      # to serve Category 3 persons.

      add_exiting_clients('Measure 6', exits_scope.category_3, :m6, (TH + SH + PSH_ONLY + RRH).freeze)
      add_project_leavers_and_stayers_m6('Measure 6')
    end

    private def add_m7_clients
      m7_exits = GrdaWarehouse::ServiceHistoryEnrollment.entry.ended_between(
        start_date: @report.start_date,
        end_date: @report.end_date + 1.day,
      )

      m7_stays = GrdaWarehouse::ServiceHistoryEnrollment.entry.ongoing(
        on_date: @report.end_date,
      )
      filter # force @filter to be set
      m7_stays = filter_for_user_access(m7_stays)
      m7_stays = filter_for_cocs(m7_stays)
      project_ids = filter.effective_project_ids
      m7_stays = m7_stays.joins(:project).where(p_t[:id].in(project_ids)) if project_ids.any?

      m7a1_exits = add_filters m7_exits.
        hud_project_type(SO).
        where.not(client_id: m7_stays.hud_project_type(SO).select(:client_id))

      process_scope_by_client('Measure 7', m7a1_exits, SHE_COLUMNS) do |client, client_enrollments|
        # 2. Of the project exits selected in step 1, determine the latest
        # project exit for each client.
        last_exit = client_enrollments.max_by { |e| e[:last_date_in_program] }

        # 3. Reference the destinations of the project exits against Appendix A
        # (row headers) and the “SO” column. Destinations indicated with an X
        # (values 6, 29, and 24) cause leavers with those destinations to be
        # completely excluded from the entire measure (all of column C).
        next if last_exit[:destination].in? [6, 29, 24]

        {
          m7a1_project_id: last_exit[:project_id],
          m7a1_destination: last_exit[:destination] || 99,
          m7_history: { enrollments: client_enrollments },
          m7_reporting_age: client_enrollments.last[:age],
          veteran: client.veteran?,
          m7_head_of_household: client_enrollments.last[:head_of_household] || false,
        }
      end

      add_project_leavers_and_stayers_m7('Measure 7')
    end

    private def add_project_leavers_and_stayers_m6(question_name)
      return unless add_clients_for_question?(question_name)

      stays = add_filters GrdaWarehouse::ServiceHistoryEnrollment.entry.ongoing(
        on_date: @report.end_date,
      ).category_3

      exits = add_filters GrdaWarehouse::ServiceHistoryEnrollment.entry.ended_between(
        start_date: @report.start_date,
        end_date: @report.end_date + 1.day,
      ).category_3

      history_field = :m6_history
      table_1_dest_field = :m6c1_destination
      table_2_dest_field = :m6c2_destination

      # Universe
      # Metric 6c.1: Safe Haven (project type 8), Transitional Housing (Project Type 2), Permanent Housing-Rapid Rehousing (Project Type 13), and PH-PSH (Project Type 3, without a housing move-in date) clients who exited during the report range.
      # Metric 6c.2: Permanent Housing – Permanent Supportive Housing (Project Type 3, with a housing move-in date) clients who are active in the report range.
      # Metric 6c.1 mirrors Measure 7b.1 but with a universe of Category 3 SH, TH, PH – RRH, and PH (without a housing move-in date) system leavers in the current reporting year.
      # Metric 6c.2 mirrors Measure 7b.2 but with a universe of Category 3 PH-PSH system stayers and leavers in the current reporting year, with a housing move-in date.
      table_1_project_types = SH + TH + RRH + PSH_ONLY
      table_2_project_types = PSH_ONLY

      # Table 1 is 6c.1
      #
      # Step 1.  Select leavers `table_1_exits` across [table_1_project_types] in the report date
      # range. A “leaver” in this metric means the client must have exited from a project of one of
      # the given types in the report date range and was not active in that or any other project
      # among the given types as of the [report end date]. `stays`
      table_1_exits = exits.
        hud_project_type(table_1_project_types).
        where.not(client_id: stays.hud_project_type(table_1_project_types).select(:client_id))

      # puts "#{table_1_dest_field} running..."
      process_scope_by_client(question_name, table_1_exits, SHE_COLUMNS) do |_client, client_enrollments|
        # 2. Of the project exits selected in step 1, determine the latest
        # project exit for each client.
        last_exit = client_enrollments.max_by { |e| e[:last_date_in_program] }
        last_exit[:destination] ||= destination_for(table_1_project_types, last_exit[:client_id], last_exit[:household_id])

        #  puts "#{table_1_dest_field} checking #{last_exit}"

        # 3. If the latest exit was from a PH-PSH project (type 3)
        # where the [housing move-in date] is <= [report end date], exclude the client completely
        # from this measure (the client will be reported in measure 6c.2).
        # If .... there is no [housing move-in date] for that stay, the client is included in this measure.
        if last_exit[:project_type].in?(PSH_ONLY) && last_exit[:MoveInDate].present? && last_exit[:MoveInDate] <= @report.end_date
          # puts "EXCLUDED #{last_exit} in Step 3 from #{table_1_dest_field}"
          next
        end

        # 4. Reference the destinations of the project exits against Appendix A
        # (row headers) using the project type from which the exit occurred
        # (column headers). Destinations indicated with an X (values 15, 6, 25,
        # 24) cause leavers with those destinations to be completely excluded
        # from the entire measure (all of column C).
        excluded_destinations = [15, 6, 25, 24]
        if last_exit[:destination].in? excluded_destinations
          # puts "EXCLUDED #{last_exit} in Step 4 from #{table_1_dest_field}"
          next
        end

        # Steps 5 - 7 are handled in the subclass
        {
          table_1_dest_field => last_exit[:destination] || 99,
          history_field => { enrollments: client_enrollments },
        }.tap do |data|
          # puts "FOUND #{last_exit} for #{table_1_dest_field}"
        end
      end

      # Table 2 is 6c.2
      #
      # Step 1. Select stayers and leavers across selected PH projects (types 3, 9 and 10).
      # “leaver” in this metric means the client must have exited from a project of one
      # of the given types in the report date range and was not active in that
      # or any other project among the given types as of the [report end date].
      # puts "#{table_2_dest_field} running #{stays.to_sql}"
      # 2. Data from PH-RRH projects is completely excluded from this metric.
      stays = stays.hud_project_type(table_2_project_types)
      exits = exits.hud_project_type(table_2_project_types)

      process_scope_by_client(question_name, stays, SHE_COLUMNS) do |_client, client_enrollments|
        last_stay = client_enrollments.max_by { |e| e[:first_date_in_program] }
        # puts "#{table_2_dest_field} checking stay #{last_stay}"

        # 3. Of the stayers selected in step 1, if the latest stay has no [housing move in date],
        # or the [housing move-in date] is > [report end date], exclude the client completely from this measure.
        if last_stay[:MoveInDate].blank? || last_stay[:MoveInDate] > @report.end_date
          # puts "EXCLUDED Stay #{last_stay} in step 3 from #{table_2_dest_field}"
          next
        end

        # Steps 5 - 7 are handled in the subclass
        {
          table_2_dest_field => 0, # stayers may have destinations, but we note them as 0 so we can identify them
          history_field => { enrollments: client_enrollments },
        }.tap do |data|
          # puts "FOUND #{last_stay} for #{table_2_dest_field}"
        end
      end

      table_2_exits = add_filters exits.hud_project_type(table_2_project_types).
        where.not(client_id: stays.select(:client_id))

      # puts "#{table_2_dest_field} running #{table_2_exits.to_sql}"
      process_scope_by_client(question_name, table_2_exits, SHE_COLUMNS) do |_client, client_enrollments|
        last_exit = client_enrollments.max_by { |e| e[:last_date_in_program] }
        # puts "#{table_2_dest_field} checking exit #{last_exit}"

        # 4. Of the leavers selected in step 1, determine the latest project exit for
        # each client. If there is no [housing move-in date] for that stay, the client is
        # completely excluded from this measure (the client will be reported in 6c.1)..
        if last_exit[:MoveInDate].blank?
          # puts "EXCLUDED Exit #{last_exit} in step 4 from #{table_2_dest_field}"
          next
        end

        # 5. Reference the destinations of the project exits against Appendix A (row headers)
        # and the “PH (all)” column. Destinations indicated with an X (values 15, 6, 25, 24)
        # cause leavers with those destinations to be completely excluded from the entire measure (all of column C).
        if last_exit[:destination].in? [15, 6, 25, 24]
          # puts "EXCLUDED Exit #{last_exit} in step 5 from #{table_2_dest_field}"
          next
        end

        # Steps 6 - 7 are handled in the subclass
        {
          table_2_dest_field => last_exit[:destination] || 99,
          history_field => { enrollments: client_enrollments },
        }.tap do |data|
          # puts "FOUND #{last_stay} for #{table_2_dest_field}"
        end
      end
    end

    private def add_project_leavers_and_stayers_m7(question_name)
      return unless add_clients_for_question?(question_name)

      stays = add_filters GrdaWarehouse::ServiceHistoryEnrollment.entry.ongoing(
        on_date: @report.end_date,
      )

      exits = add_filters GrdaWarehouse::ServiceHistoryEnrollment.entry.ended_between(
        start_date: @report.start_date,
        end_date: @report.end_date + 1.day,
      )

      history_field = :m7b_history
      project_field = :m7b_project_id
      table_1_dest_field = :m7b1_destination
      table_2_dest_field = :m7b2_destination
      reporting_age_col = :m7_reporting_age
      head_of_household_col = :m7_head_of_household

      # Universe
      # Metric 7b.1: Emergency Shelter (Project Type 1), Safe Haven (project type 8), Transitional Housing (Project Type 2), and Permanent Housing-Rapid Rehousing (Project Type 13) clients who exited during the report range, plus other PH (project types 3, 9, 10) clients who exited without moving into housing.
      # Metric 7b.2: Permanent Housing – Permanent Supportive Housing (Project Type 3), Permanent Housing-Housing Only (Project Type 9) and Permanent Housing-Housing Services only (Project Type 10) clients who are active in the report range with a housing move-in date.
      # Metric 7b.1: Select leavers across all ES, SH, TH, PH-RRH, and PH projects ...
      # Metric 7b.2: Select stayers and leavers across selected PH projects (types 3, 9 and 10) ...
      table_1_project_types = ES + SH + TH + PH
      table_2_project_types = PSH_ONLY + OPH

      # Table 1 is 7b.1
      #
      # Step 1.  Select leavers `table_1_exits` across [table_1_project_types] in the report date
      # range. A “leaver” in this metric means the client must have exited from a project of one of
      # the given types in the report date range and was not active in that or any other project
      # among the given types as of the [report end date]. `stays`
      table_1_exits = exits.
        hud_project_type(table_1_project_types).
        where.not(client_id: stays.hud_project_type(table_1_project_types).select(:client_id))

      # puts "#{table_1_dest_field} running..."
      process_scope_by_client(question_name, table_1_exits, SHE_COLUMNS) do |client, client_enrollments|
        # 2. Of the project exits selected in step 1, determine the latest
        # project exit for each client.
        last_exit = client_enrollments.max_by { |e| e[:last_date_in_program] }
        last_exit[:destination] ||= destination_for(table_1_project_types, last_exit[:client_id], last_exit[:household_id])

        #  puts "#{table_1_dest_field} checking #{last_exit}"

        # 3. If the latest exit was from a PH project (types 3, 9 and 10)
        # where the [housing move-in date] is <= [report end date], exclude the client completely
        # from this measure (the client will be reported in measure 7b.2).
        # If .... there is no [housing move-in date] for that stay, the client is included in this measure.
        if last_exit[:project_type].in?(PH_PSH) && last_exit[:MoveInDate].present? && last_exit[:MoveInDate] <= @report.end_date
          # puts "EXCLUDED #{last_exit} in Step 3 from #{table_1_dest_field}"
          next
        end

        # 4. Reference the destinations of the project exits against Appendix A
        # (row headers) using the project type from which the exit occurred
        # (column headers). Destinations indicated with an X (values 15, 6, 25,
        # 24) cause leavers with those destinations to be completely excluded
        # from the entire measure (all of column C).
        excluded_destinations = [15, 6, 25, 24]

        if last_exit[:destination].in? excluded_destinations
          # puts "EXCLUDED #{last_exit} in Step 4 from #{table_1_dest_field}"
          next
        end

        max_enrollment = client_enrollments.max_by { |en| en[:first_date_in_program] }
        # Steps 5 - 7 are handled in the subclass
        {
          table_1_dest_field => last_exit[:destination] || 99,
          history_field => { enrollments: client_enrollments },
          project_field => max_enrollment[:project_id],
          reporting_age_col => age_for_report(dob: client.dob, entry_date: max_enrollment[:first_date_in_program], age: max_enrollment[:age]),
          head_of_household_col => max_enrollment[:head_of_household],
        }.tap do |data|
          # puts "FOUND #{last_exit} for #{table_1_dest_field}"
        end
      end

      # Table 2 is 7b.2
      #
      # Step 1. Select stayers and leavers across selected PH projects (types 3, 9 and 10).
      # “leaver” in this metric means the client must have exited from a project of one
      # of the given types in the report date range and was not active in that
      # or any other project among the given types as of the [report end date].
      # puts "#{table_2_dest_field} running #{stays.to_sql}"
      # 2. Data from PH-RRH projects is completely excluded from this metric.
      stays = stays.hud_project_type(table_2_project_types)
      exits = exits.hud_project_type(table_2_project_types)

      process_scope_by_client(question_name, stays, SHE_COLUMNS) do |client, client_enrollments|
        last_stay = client_enrollments.max_by { |e| e[:first_date_in_program] }
        # puts "#{table_2_dest_field} checking stay #{last_stay}"

        # 3. Of the stayers selected in step 1, if the latest stay has no [housing move in date],
        # or the [housing move-in date] is > [report end date], exclude the client completely from this measure.
        if last_stay[:MoveInDate].blank? || last_stay[:MoveInDate] > @report.end_date
          # puts "EXCLUDED Stay #{last_stay} in step 3 from #{table_2_dest_field}"
          next
        end

        max_enrollment = client_enrollments.max_by { |en| en[:first_date_in_program] }
        # Steps 5 - 7 are handled in the subclass
        {
          table_2_dest_field => 0, # stayers may have destinations, but we note them as 0 so we can identify them
          history_field => { enrollments: client_enrollments },
          project_field => max_enrollment[:project_id],
          reporting_age_col => age_for_report(dob: client.dob, entry_date: max_enrollment[:first_date_in_program], age: max_enrollment[:age]),
          head_of_household_col => max_enrollment[:head_of_household],
        }.tap do |data|
          # puts "FOUND #{last_stay} for #{table_2_dest_field}"
        end
      end

      table_2_exits = add_filters exits.
        hud_project_type(
          table_2_project_types,
        ).where.not(
          client_id: stays.select(:client_id),
        )

      # puts "#{table_2_dest_field} running #{table_2_exits.to_sql}"
      process_scope_by_client(question_name, table_2_exits, SHE_COLUMNS) do |client, client_enrollments|
        last_exit = client_enrollments.max_by { |e| e[:last_date_in_program] }
        # puts "#{table_2_dest_field} checking exit #{last_exit}"

        # 4. Of the leavers selected in step 1, determine the latest project exit for
        # each client. If there is no [housing move-in date] for that stay, the client is
        # completely excluded from this measure (the client will be reported in 7b.1)..
        if last_exit[:MoveInDate].blank?
          # puts "EXCLUDED Exit #{last_exit} in step 4 from #{table_2_dest_field}"
          next
        end

        # 5. Reference the destinations of the project exits against Appendix A (row headers)
        # and the “PH (all)” column. Destinations indicated with an X (values 15, 6, 25, 24)
        # cause leavers with those destinations to be completely excluded from the entire measure (all of column C).
        if last_exit[:destination].in? [15, 6, 25, 24]
          # puts "EXCLUDED Exit #{last_exit} in step 5 from #{table_2_dest_field}"
          next
        end

        # Steps 6 - 7 are handled in the subclass
        {
          table_2_dest_field => last_exit[:destination] || 99,
          history_field => { enrollments: client_enrollments },
          project_field => last_exit[:project_id],
          reporting_age_col => age_for_report(dob: client.dob, entry_date: last_exit[:first_date_in_program], age: last_exit[:age]),
          head_of_household_col => last_exit[:head_of_household],
        }.tap do |data|
          # puts "FOUND #{last_stay} for #{table_2_dest_field}"
        end
      end
    end

    private def add_exiting_clients(question_name, m_exits_scope, m_code, project_types)
      return unless add_clients_for_question?(question_name)

      homeless_project_types = (ES + SO + SH).freeze

      exit_from_project_type_col = :"#{m_code}_exit_from_project_type"
      exit_to_destination_col = :"#{m_code}_exit_to_destination"
      reentry_days_col = :"#{m_code}_reentry_days"
      history_col = :"#{m_code}_history"
      reporting_age_col = :"#{m_code}_reporting_age"
      head_of_household_col = :"#{m_code}_head_of_household"

      updated_columns = [
        :dob,
        :first_name,
        :last_name,
        :veteran,
        exit_from_project_type_col,
        exit_to_destination_col,
        reentry_days_col,
        history_col,
        reporting_age_col,
        head_of_household_col,
      ].freeze

      each_client_batch(m_exits_scope, start_date: lookback_start_date, end_date: @report.end_date) do |clients_by_id|
        spm_clients = {}

        exits_by_client_id = exits_for_batch(m_exits_scope, clients_by_id.keys, SHE_COLUMNS).group_by do |e|
          e[:client_id]
        end.freeze
        entries_by_client_id = entries_for_batch(clients_by_id.keys, SHE_COLUMNS).group_by do |e|
          e[:client_id]
        end.freeze

        exits_by_client_id.each do |client_id, client_exits|
          # 2. Of the universe of project exits, determine each client’s
          # earliest [project exit date] where the [destination] was permanent housing.
          p_exit = client_exits.sort_by { |d| d[:last_date_in_program] }.detect do |client_exit|
            # inherit destination from HoH if age <= 17 and destination not collected
            client_exit[:destination] = destination_for(project_types, client_exit[:client_id], client_exit[:household_id]) unless client_exit[:destination].present? && client_exit[:destination] != 99

            permanent_destination?(client_exit[:destination])
          end

          next unless p_exit

          # 3. Using data from step 2, report the distinct number of clients who exited to permanent housing destinations
          # according to the project type associated with the client’s earliest applicable exit (cells B2-B6).

          client = clients_by_id.fetch(client_id)
          spm_client = report_client_universe.new(
            report_instance_id: @report.id,
            client_id: client.id,
            data_source_id: client.data_source_id,
            dob: client.DOB,
            first_name: client.first_name,
            last_name: client.last_name,
            veteran: client.veteran?,
          )

          # 4. Using data from step 2, report the distinct number of clients who exited to permanent housing destinations
          # without regard to the project type associated with the client’s earliest applicable exit (cell B7).
          spm_client[exit_from_project_type_col] = p_exit[:project_type]
          spm_client[exit_to_destination_col] = p_exit[:destination] || 99

          # 5. Using data from step 2, scan forward in time beginning from each client’s [project exit date]
          # with a permanent housing destination to see if the client has a project start into a project
          # indicating the client is now homeless again.

          # 5.a && 5.d
          reentries = entries_by_client_id[client_id]&.select do |e|
            (e[:first_date_in_program] >= p_exit[:last_date_in_program]) && (e[:first_date_in_program] <= @report.end_date)
          end&.sort_by do |e|
            e[:last_date_in_program] || @report.end_date
          end || []

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
              if previous_exit_from_ph.present?
                (entry_date - previous_exit_from_ph).to_i > 14
              else
                false # If there is no previous exit from PH, it can't have been 14 days
              end
            end

            previous_exit_from_ph = entry[:last_date_in_program] if entry[:project_type].in?(PH + TH)

            found
          end

          # 6. Use the [project start date] found in step 5 to calculate the number of days between the
          # client’s [project exit date] from step 2 until the client was identified
          # as homeless again.
          spm_client[reentry_days_col] = if reentry
            reentry[:first_date_in_program] - p_exit[:last_date_in_program]
          else
            0
          end

          # Audit of exit/entries we considered
          spm_client[history_col] = {
            exit: p_exit,
            reentries: reentries,
          }
          spm_client["#{m_code}_project_id"] = p_exit[:project_id] unless m_code.to_s == 'm6'

          max_enrollment = reentries.max_by { |en| en[:first_date_in_program] }
          spm_client[reporting_age_col] = age_for_report(dob: spm_client.dob, entry_date: max_enrollment[:first_date_in_program], age: max_enrollment[:age]) if max_enrollment.present?
          spm_client[head_of_household_col] = max_enrollment.try(:[], :head_of_household) || false

          spm_clients[client] = spm_client
        end

        # Steps 7 - 9 are handled in MeasureTwo#run_question!
        append_report_clients(question_name, spm_clients, updated_columns)
      end
    end

    # 1. The selection of relevant projects is critical to this measure.
    # Build the universe of relevant projects for this measure as follows:
    # Select projects where
    #   [Federal Partner Programs and Components] is 2, 3, 4, 5, 43, 44
    #   and
    #   [grant start date] <= [report end date]
    #   and
    #   ( [grant end date] is null or [grant end date] >= [report start date] )
    #   and
    #   [project type] is 2, 3, 8, 9, 10, or 13
    # Page 24 of 36
    private def m4_coc_program_funded_enrollments
      funding_sources = [2, 3, 4, 5, 43, 44]

      funded = GrdaWarehouse::ServiceHistoryEnrollment.entry.joins(:client).
        grant_funded_between(start_date: @report.start_date, end_date: @report.end_date + 1.day).
        where(Funder: { Funder: funding_sources }).
        hud_project_type(PH + SH + TH)
      filter # force @filter to be set
      funded = filter_for_user_access(funded)
      funded = filter_for_cocs(funded)
      funded
    end

    # A “system stayer” is a client active in any one or more of the relevant
    # projects as of the [report end date].
    private def m4_stayers_scope
      add_filters m4_coc_program_funded_enrollments.ongoing(
        on_date: @report.end_date,
      )
    end

    # A “system leaver” is any client who has exited from one or more of the
    # relevant projects between [report start date] and [report end date] and
    # is not active in any of the relevant projects as of the [report end date]
    private def m4_leavers_scope
      add_filters m4_coc_program_funded_enrollments.ended_between(
        start_date: @report.start_date,
        end_date: @report.end_date + 1.days,
      ).where.not(
        client_id: m4_stayers_scope.select(:client_id),
      )
    end

    # Make a useful Hash of income assessment data collected on or before
    # @report.end_date
    # {
    #   DataCollectionStage => {
    #     InformationDate => [
    #       {IncomeFromAnySource:, :TotalMonthlyIncome, :EarnedAmount, ...}
    #     ]
    # }
    private def income_and_benefits(enrollment_group_id:, data_source_id:)
      columns = {
        EnrollmentID: :EnrollmentID,
        data_source_id: :data_source_id,
        IncomeFromAnySource: :IncomeFromAnySource,
        TotalMonthlyIncome: :TotalMonthlyIncome,
        EarnedAmount: :EarnedAmount,
        InformationDate: :InformationDate,
        DataCollectionStage: :DataCollectionStage,
      }
      @income_and_benefits ||= {}.tap do |income_map|
        GrdaWarehouse::Hud::IncomeBenefit.
          joins(enrollment: :service_history_enrollment).
          where(she_t[:id].in(Arel.sql(active_enrollments_scope.select(:id).to_sql))).
          where(ib_t[:InformationDate].lteq(@report.end_date)).
          order(InformationDate: :asc).
          pluck(*columns.values).map do |r|
            Hash[columns.keys.zip(r)]
          end.each do |row|
            enrollment_key = [row[:data_source_id], row[:EnrollmentID]]
            stage = row[:DataCollectionStage]
            information_date = row[:InformationDate]
            income_map[enrollment_key] ||= {}
            income_map[enrollment_key][stage] ||= {}
            income_map[enrollment_key][stage][information_date] ||= []
            income_map[enrollment_key][stage][information_date] << row
          end
      end
      @income_and_benefits[[data_source_id, enrollment_group_id]]
    end

    # Add stayer related income fields to the row and return it.
    #
    # Returns nil if no earlier income report could be found
    private def add_stayer_income(row)
      income_map = income_and_benefits(
        enrollment_group_id: row[:enrollment_group_id],
        data_source_id: row[:data_source_id],
      )
      return nil unless income_map.present?

      # This spec said:
      # f. For each client, determine the most recent Income and Sources
      # record with a [data collection stage] of annual assessment (5)
      # attached to the selected project stay where the [information date] of
      # the record is no more than 30 days before or after the month and day
      # of the associated [project start date]. This becomes the client’s
      # later data point for comparing income. It is necessary to determine
      # this data point before determining the earlier point of comparison.
      # [information date] <= [report end date] and [data collection stage] =
      # 5

      # g. For each client, determine the most recent Income and Sources
      # annual assessment attached to the selected project stay. If the client
      # has no previous annual assessment records, use the client’s Income and
      # Sources at project start. This becomes the client’s earlier data point
      # for comparing income. Please note that for long-term permanent housing
      # clients, the [project start date] may be before the [Lookback Stop
      # Date]. This is the only exception when data collected before the
      # [Lookback Stop Date] may be required. [information date] <
      # [information date of annual assessment from step 2g.] and [data
      # collection stage] = 5 or 1

      # TODO? What we have done the below is FY2019

      # If we have more than one 5, use the first as the earliest,
      # otherwise if we have a 1 group use that, if not, we won't calculate
      earliest = if income_map[5].present? && income_map[5].size > 1
        income_map[5].values.first.first
      elsif income_map[1].present?
        income_map[1].values.first.first
      end

      # h. Clients who are completely missing their earlier data point, i.e. clients missing
      # Income and Sources at project start, are excluded entirely from the universe of clients.
      return nil unless earliest

      if earliest[:IncomeFromAnySource] == 1
        row[:earliest_income] = earliest[:TotalMonthlyIncome] || 0
        row[:earliest_earned_income] = earliest[:EarnedAmount] || 0
        row[:earliest_non_earned_income] = row[:earliest_income] - row[:earliest_earned_income]
      else
        row[:earliest_income] = 0
        row[:earliest_earned_income] = 0
        row[:earliest_non_earned_income] = 0
      end

      # h. Clients who have been in the project 365 or more days but who are completely missing
      # their later data point are included in the universe of clients (cell C2) but cannot be
      # counted as having an increase in any type of income (cell C3).

      # Grab the last day from the 5 (annual assessment) group
      latest = income_map[5].values.last.first if income_map[5].present?

      if latest.present? && latest[:IncomeFromAnySource] == 1
        row[:latest_income] = latest[:TotalMonthlyIncome] || 0
        row[:latest_earned_income] = latest[:EarnedAmount] || 0
        row[:latest_non_earned_income] = row[:latest_income] - row[:latest_earned_income]
      end

      row
    end

    # Add stayer related income fields to the row and return it.
    #
    # Returns nil if no earlier income report could be found
    private def add_leaver_income(row)
      income_map = income_and_benefits(
        enrollment_group_id: row[:enrollment_group_id],
        data_source_id: row[:data_source_id],
      )

      # The spec says:
      # e. For each client, determine the client’s income assessment record at
      # project exit. This becomes the client’s later data point for comparing
      # income. [information date] = [project exit date] and [data collection
      # stage] = 3

      # f. For each client, determine the client’s income assessment record at
      # project start. This becomes the client’s earlier data point for
      # comparing income. Please note that for long-term permanent housing
      # clients, the [project start date] may be before the [Lookback Stop
      # Date]. This is the only exception when data collected before the
      # [Lookback Stop Date] may be required. [information date] = [project
      # start date] and [data collection stage] = 1

      # TODO? What we have done the below is FY2019

      # Latest entry interview (Stage=1) associated with this enrollment's entry.
      # The spec compare InformationDate but we historically just found the best candidate
      # linked to the enrollment
      earliest = income_map[1].values.first.first if income_map.try(:[], 1)

      # g. Clients who are completely missing their Income and Sources at project start
      # are excluded entirely from the universe of clients.
      return nil unless earliest

      if earliest[:IncomeFromAnySource] == 1
        row[:earliest_income] = earliest[:TotalMonthlyIncome] || 0
        row[:earliest_earned_income] = earliest[:EarnedAmount] || 0
        row[:earliest_non_earned_income] = row[:earliest_income] - row[:earliest_earned_income]
      else
        row[:earliest_income] = 0
        row[:earliest_earned_income] = 0
        row[:earliest_non_earned_income] = 0
      end

      # h. Clients missing their Income and Sources at exit are included in the universe of
      # clients (cell C2) but cannot be counted as having an increase in any type of income (cells C3 and C4

      # Latest exit interview (Stage=3) associated with this enrollment's exit.
      # The spec compare InformationDate but we historically just found the best candidate
      # linked to the enrollment
      latest = income_map[3].values.last.first if income_map.try(:[], 3)

      if latest.present? && latest[:IncomeFromAnySource] == 1
        row[:latest_income] = latest[:TotalMonthlyIncome] || 0
        row[:latest_earned_income] = latest[:EarnedAmount] || 0
        row[:latest_non_earned_income] = row[:latest_income] - row[:latest_earned_income]
      end

      row
    end

    private def pluck_to_hash(columns, scope)
      scope.pluck(*columns.values).map do |row|
        Hash[columns.keys.zip(row)]
      end
    end

    private def exits_for_batch(scope, client_ids, columns)
      pluck_to_hash columns, scope.where(
        client_id: client_ids,
      )
    end

    private def entries_for_batch(client_ids, columns)
      pluck_to_hash columns, enrollments_scope.
        where(client_id: client_ids)
    end

    private def destination_for(project_types, client_id, household_id)
      children_without_destination(project_types)[[client_id, household_id]]
    end

    private def children_without_destination(project_types)
      # PERF: batch this... right now it loads ALL enrollments with service during the report range
      # 99 = Not collected
      destination_not_collected = [99]

      @child_ids ||= {}
      @child_ids[project_types] ||= begin
        child_candidates_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
          hud_project_type(project_types).
          open_between(start_date: @report.start_date - 2.years, end_date: @report.end_date).
          with_service_between(start_date: @report.start_date - 2.years, end_date: @report.end_date).
          joins(:enrollment, :client).
          where(
            she_t[:destination].in(destination_not_collected).or(she_t[:destination].eq(nil)),
            c_t[:DOB].not_eq(nil).and(c_t[:DOB].lteq(@report.start_date - 17.years)),
          ).
          distinct.
          select(:client_id)

        scope = add_filters(child_candidates_scope)

        child_candidates = scope.
          pluck(
            :client_id,
            c_t[:DOB],
            e_t[:EntryDate],
            :age,
            :head_of_household_id,
            she_household_column,
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
      # PERF: batch this... right now it loads ALL enrollments with service during the report range
      @hoh_destinations ||= {}
      @hoh_destinations[project_types] ||= GrdaWarehouse::ServiceHistoryEnrollment.entry.
        hud_project_type(project_types).
        open_between(start_date: @report.start_date - 2.years, end_date: @report.end_date).
        with_service_between(start_date: @report.start_date - 2.years, end_date: @report.end_date).
        joins(:client).
        where(she_t[:head_of_household].eq(true)).
        distinct.
        pluck(
          :head_of_household_id,
          :destination,
          she_household_column,
        ).
        map do |(hoh_id, destination, household_id)|
          [[hoh_id, household_id], destination]
        end.to_h
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

    private def services_scope
      scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
        hud_project_type(ES_SH_TH_PH).
        joins(:service_history_services, :enrollment)

      add_filters(scope)
    end

    private def active_enrollments_scope
      scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.hud_project_type(ES_SH_TH_PH)
      scope = scope.with_service_between(
        start_date: @report.start_date - 1,
        end_date: @report.end_date,
      )

      add_filters(scope)
    end

    private def m5_enrollments_scope
      add_filters GrdaWarehouse::ServiceHistoryEnrollment.
        open_between(start_date: lookback_start_date, end_date: @report.end_date).
        with_service_between(start_date: lookback_start_date, end_date: @report.end_date).
        hud_project_type(ES_SH_TH_PH_SO)
    end

    private def lookback_start_date
      [LOOKBACK_STOP_DATE, @report.start_date - 730.days].max
    end

    private def lookback_range
      lookback_start_date .. (@report.end_date - 730.days)
    end

    private def exits_scope
      exits = GrdaWarehouse::ServiceHistoryEnrollment.entry.
        joins(:project).hud_project_type(ES_SH_TH_PH_SO).
        where(last_date_in_program: lookback_range)
      filter # force @filter to be set
      project_ids = filter.effective_project_ids
      exits = exits.joins(:project).where(p_t[:id].in(project_ids)) if project_ids.any?
      exits = filter_for_user_access(exits)
      exits = filter_for_cocs(exits)
      exits
    end

    private def enrollments_scope
      add_filters GrdaWarehouse::ServiceHistoryEnrollment.entry.where(
        first_date_in_program: lookback_start_date .. @report.end_date,
      ).hud_project_type(ES_SH_TH_PH_SO)
    end

    # Calculate the number of unique days homeless given:
    #
    # sh_enrollments: an Array(GrdaWarehouse::ServiceHistoryEnrollments) for a client with suitable preloads
    #   covering all dates that could contribute to this report
    # project_types: Array(HUD.project_types.keys)
    # stop_project_types: Array(HUD.project_types.keys)
    # include_pre_entry: boolean true to include days before entry
    #
    # The flags are set like so
    # Measure 1a / Metric 1: Persons in ES and SH – do not include data from element 3.917.
    # Measure 1a / Metric 2: Persons in ES, SH, and TH – do not include data from element 3.917.
    # Measure 1b / Metric 1: Persons in ES, SH, and PH – include data from element 3.917 and time between [project start] and [housing move-in].
    # Measure 1b / Metric 2: Persons in ES, SH, TH, and PH – include data from element 3.917 and time between [project start] and [housing move-in].
    # Measure 1b: Lines 1 and 2 include clients active in any permanent housing project (project types 3, 9, 10, 13) where all of the following are true: The [living situation] is “literally homeless” as defined above
    #  And (
    #  ( [project start date] >= [report start date] and [project start date] <= [report end date] ) Or
    #  ( [housing move-in date] >= [report start date] and [housing move-in date] <= [report end date] )
    #  Or
    #  ( [housing move-in date] is null and [project exit date] >= [report start date] and [project exit date] <= [report end date])

    def calculate_valid_days_in_project_type(all_nights, project_types:, line:, debug: false) # rubocop:disable Lint/UnusedMethodArgument,Metrics/PerceivedComplexity
      # we need to throw out any nights in PH projects where the enrollment
      # doesn't meet these critera (not homeless during the reporting period)
      # And (
      # ( [project start date] >= [report start date] and [project start date] <= [report end date] ) Or
      # ( [housing move-in date] >= [report start date] and [housing move-in date] <= [report end date] )
      # Or
      # ( [housing move-in date] is null and [project exit date] >= [report start date] and [project exit date] <= [report end date])

      # For measures 1a.1 and 1b.1, time spent by clients housed in TH or PH projects negates overlapping time spent in ES and SH projects.
      # b. For measures 1a.2 and 1b.2, time spent by clients housed in PH projects negates overlapping time spent in TH projects.
      # c. For all PH projects (project types 3, 9, 10, 13) – use clients’ [housing move-in date] to negate overlapping time spent homeless. Records where the [housing move-in date] is null (i.e. the client is not physically in permanent housing) or > the [report end date] should not negate the client’s time homeless.
      # binding.pry if debug
      # if 1a, remove any pre-entry days
      all_nights.reject! { |night| night[:pre_entry] } if line.in?([:m1a1, :m1a2])
      # reject any nights where move-in date is totally invalid
      all_nights.reject! { |night| night[:project_type].in?(PH) && night[:MoveInDate].present? && night[:MoveInDate] < night[:first_date_in_program] }

      nights_for_negation = all_nights.deep_dup
      nights_for_negation = nights_for_negation.group_by { |night| night[:date] }

      # Remove any project not in the project types we care about
      # Ignore nights in a project that are on the date of exit
      # never count days after move-in
      all_nights.reject! do |night|
        not_in_project_type = ! night[:project_type].in?(project_types)
        on_exit_date = night[:date] == night[:last_date_in_program]
        not_in_project_type || on_exit_date || night[:housed]
      end

      # if 1b, remove any non-literally homeless at entry enrollments
      # and any PH enrollment where entry, move-in, and exit is outside of report range
      if line.in?([:m1b1, :m1b2])
        all_nights.select! do |night|
          # non-PH projects
          # (night[:literally_homeless] && !night[:project_type].in?(PH)) ||
          ! night[:project_type].in?(PH) ||
          # PH literally homeless and with something during the range
          (
            night[:literally_homeless] &&
            night[:project_type].in?(PH) &&
            # opened during report range
            (
              (
                night[:first_date_in_program].present? &&
                night[:first_date_in_program] > @report.start_date &&
                night[:first_date_in_program] <= @report.end_date
              ) ||
              # moved in during report range
              (
                night[:MoveInDate].present? &&
                night[:MoveInDate] > @report.start_date &&
                night[:MoveInDate] <= @report.end_date
              ) ||
              # exited during report range without moving in
              (
                night[:MoveInDate].blank? &&
                night[:last_date_in_program].present? &&
                night[:last_date_in_program] >= @report.start_date &&
                night[:last_date_in_program] <= @report.end_date
              )
            )
          )
        end
      end

      # group by date so we can reject dates where stop-projects are present
      all_nights = all_nights.group_by { |night| night[:date] }
      # remove any days with a stop project type
      all_nights.each do |date, nights|
        if line.in?([:m1a1, :m1b1])
          remove_homeless_if = nights_for_negation[date].any? { |night| night[:project_type].in?(TH) || (night[:project_type].in?(PH) && night[:housed]) }
          nights.reject! { |night| night[:project_type].in?(ES_SH) } if remove_homeless_if
          # Negate any time earlier in the Continuum
          # Specifically, 6.a.vi says "Apply the same logic as described in step 2 above which may negate some nights that would otherwise be included" and 6.b.vi says "Apply the same logic as described in step 2 above which may negate some nights that would otherwise be included. This logic applies when including bed nights between the [project start date] and the [project exit date] as well as bed nights included because of data in element [3.917.3]."

          # Steps 2.a and 2.b are intended to provide an order of operations for determining which type of bed night takes precedence when enrollments of different types overlap. The important part for the purposes of determining this particular client's bed night is the line "Bed night dates selected in step 1 can be negated by overlapping HMIS records indicating more definitively that the client is in another type of housing “further along” in the CoC" in step 2, which also applies to bed nights based on a client's homelessness start date.
          nights.reject! { |night| night[:project_type].in?(PH) && (night[:pre_move_in] || night[:pre_entry]) } if remove_homeless_if
        else
          remove_th_if = nights_for_negation[date].any? { |night| night[:project_type].in?(PH) && night[:housed] }
          nights.reject! { |night| night[:project_type].in?(TH) } if remove_th_if
        end
        all_nights[date] = nights
        all_nights.delete(date) if nights.blank?
      end

      dates = all_nights.keys.sort

      if dates.any?
        # Find the latest bed night (stopping at the report date end)
        client_end_date = [dates.last.to_date, @report.end_date].min
        # Rails.logger.info "Latest Homeless Bed Night: #{client_end_date}"

        # Determine the client's start date
        client_start_date = [client_end_date.to_date - 365.days, LOOKBACK_STOP_DATE].max
        # Rails.logger.info "Client's initial start date: #{client_start_date}"
        days_before_client_start_date = dates.select do |d|
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
        # Rails.logger.info "Days homeless before limits #{dates.count}"
        dates.delete_if { |d| d.to_date < client_start_date.to_date || d.to_date > client_end_date.to_date }
        # Rails.logger.info "Days homeless after limits #{dates.count}"
      end
      # binding.pry if debug
      # If the client doesn't have any days within the report range in the appropriate project types, exclude them
      return nil if dates.all? { |d| d < @report.start_date || d > @report.end_date }

      dates.uniq.count
    end

    # The SPM reports need to consider nights that are not recorded
    # directly as service_nights. We are looking at two time-frames:
    #
    #  pre_entry:
    #    A night between the self-reported DateToStreetESSH (Question 3.917.3) clamped
    #    to be on or after LOOKBACK_STOP_DATE and DOB and before first_date_in_program
    #  pre_move_in:
    #    A night between an entry into a PH program and the move-in date
    #
    def generate_non_service_dates(nights)
      # Add fake records for every day between DateToStreetESSH and first_date_in_program.

      # Find the first entry for each enrollment based on unique project and first_date in program
      entries = nights.index_by do |m|
        [m[:project_id], m[:first_date_in_program]]
      end

      entries.each do |_, entry|
        next unless literally_homeless?(entry)

        # 3.917.3 - add any days prior to project entry only if client was literally homeless at entry
        next unless entry[:DateToStreetESSH].present? && entry[:first_date_in_program] > entry[:DateToStreetESSH]

        start_date = [entry[:DateToStreetESSH]&.to_date, LOOKBACK_STOP_DATE, entry[:DOB]&.to_date].compact.max
        new_nights = (start_date..entry[:first_date_in_program]).map do |date|
          new_night = entry.dup
          new_night[:date] = date
          new_night[:pre_entry] = true
          new_night[:housed] = false
          new_night[:literally_homeless] = true
          new_night
        end
        nights += new_nights
      end

      # re-sort them
      nights.sort_by { |m| m[:date] }
    end

    private def permanent_destination?(dest)
      PERMANENT_DESTINATIONS.include?(dest)
    end

    private def literally_homeless?(night)
      # use the cache if we have it
      @literally_homeless ||= {}
      return @literally_homeless[night[:enrollment_id]] unless @literally_homeless[night[:enrollment_id]].nil?

      # Get client_id, enrollment_id pairs for es_so_sh for all enrollments open during range (filter applied)
      # Get client_id, enrollment_id pairs for ph_th for all enrollments open during range (filter applied)
      # If client_id and enrollment_id are in set, return true
      # else if client is > 17 return false
      # else figure out if HoH is in group
      # [project type] = 1, 4, 8
      # Or (
      # [project type] = 2, 3, 9, 10 13 And (
      # [living situation] = 16, 1, 18
      # Or (
      # [living situation] = 15, 6, 7, 25, 4, 5
      # And [Did you stay less than 90 days?] = 1 # LOSUnderThreshold (3.917.2A)
      # And [On the night before did you stay on the streets, ES or SH] = 1 # PreviousStreetESSH (3.917.2C)
      # )
      # Or (
      # [living situation] = 29, 14, 2, 32, 36, 35, 28, 19, 3, 31, 33, 34, 10, 20, 21, 11, 8, 9, 99
      # And [Did you stay less than 7 nights?] = 1 # LOSUnderThreshold (3.917.2A)
      # And [On the night before did you stay on the streets, ES or SH] = 1 # PreviousStreetESSH (3.917.2C)
      # ) )
      # )

      if night[:project_type].in?(ES + SH + SO)
        @literally_homeless[night[:enrollment_id]] = true
        return @literally_homeless[night[:enrollment_id]]
      end

      th_ph = night[:project_type].in?(TH + PH)
      if th_ph && night[:LivingSituation].in?(HOMELESS_LIVING_SITUATIONS)
        @literally_homeless[night[:enrollment_id]] = true
        return @literally_homeless[night[:enrollment_id]]
      end

      on_streets_and_under_threshold = night[:LOSUnderThreshold] == 1 && night[:PreviousStreetESSH] == 1
      if th_ph && on_streets_and_under_threshold && night[:LivingSituation].in?(INSTITUTIONAL_LIVING_SITUATIONS + HOUSED_LIVING_SITUATIONS)
        @literally_homeless[night[:enrollment_id]] = true
        return @literally_homeless[night[:enrollment_id]]
      end

      # Stop, since we can't calculate further for adults, HoH, or anyone without a household id
      if night[:HouseholdID].blank? || night[:age].blank? || night[:age] > 17 || night[:head_of_household]
        @literally_homeless[night[:enrollment_id]] = false
        return @literally_homeless[night[:enrollment_id]]
      end

      # Don't calculate for children if they have some value on their record
      if night[:LOSUnderThreshold].present?
        @literally_homeless[night[:enrollment_id]] = false
        return @literally_homeless[night[:enrollment_id]]
      end

      # Children may inherit living the living situation from their HoH
      hoh_enrollment = hoh_enrollment_for(night)
      if hoh_enrollment.blank?
        @literally_homeless[night[:enrollment_id]] = false
        return @literally_homeless[night[:enrollment_id]]
      end

      # don't assume anything if they arrived at a different time
      if hoh_enrollment[:first_date_in_program] != night[:first_date_in_program]
        @literally_homeless[night[:enrollment_id]] = false
        return @literally_homeless[night[:enrollment_id]]
      end

      @literally_homeless[night[:enrollment_id]] = literally_homeless?(hoh_enrollment)
      @literally_homeless[night[:enrollment_id]]
    end

    private def hoh_enrollment_for(night)
      @hoh_enrollment_for ||= begin
        columns = {
          enrollment_id: she_t[:id],
          project_type: she_t[:computed_project_type],
          project_id: p_t[:id],
          first_date_in_program: she_t[:first_date_in_program],
          last_date_in_program: she_t[:last_date_in_program],
          HouseholdID: e_t[:HouseholdID],
          DateToStreetESSH: e_t[:DateToStreetESSH],
          LivingSituation: e_t[:LivingSituation],
          LOSUnderThreshold: e_t[:LOSUnderThreshold], # [Did you stay less than 90 days?]
          PreviousStreetESSH: e_t[:PreviousStreetESSH], # [On the night before did you stay on the streets, ES or SH]
          MoveInDate: she_t[:move_in_date],
          head_of_household: she_t[:head_of_household],
          data_source_id: e_t[:data_source_id],
        }
        pluck_to_hash(
          columns,
          active_enrollments_scope.heads_of_households,
        ).index_by { |row| [row[:HouseholdID], row[:project_id], row[:data_source_id]] }
      end
      @hoh_enrollment_for[[night[:HouseholdID], night[:project_id], night[:data_source_id]]]
    end
  end
end
