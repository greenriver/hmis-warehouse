###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ReportGenerators::SystemPerformance::Fy2019
  class MeasureSix < Base
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
    RRH = [13]
    PH_PSH = [3,9,10]
    PERMANENT_DESTINATIONS = [3, 10, 11, 19, 20, 21, 22, 23, 26, 28]
    TEMPORARY_DESTINATIONS = [1, 15, 6, 14, 7, 27, 16, 4, 29, 18, 12, 13, 5, 2, 25]

    def run!
      # Disable logging so we don't fill the disk
      ActiveRecord::Base.logger.silence do
        calculate()
        Rails.logger.info "Done"
      end # End silence ActiveRecord Log
    end

    private

    def calculate
      # NOTE: HousingStatusAtEntry & HousingStatusAtExit = 5 -- this is where we determine if someone is a Category 3 (value would be 5)
      # This shows up in ProgramParticipation.  No one has HousingStatusAtEntry = 5.  Only at exit
      # the 2020 spec removed HousingStatus from Enrollment.csv, so we're limited to
      # Exit.HousingAssessment == 5

      # NOTE: Dependents do get flagged correctly as Category 3 if attached to a Head of Household
      # Category 3 covers families with children and youth or youth under the age of 25 who are considered homeless under other federal statutes because of their living situation but who are not literally homeless. These federal statutes include the Runaway & Homeless Youth Act, Head Start Act, Violence Against Women Act, and the Department of Education section of the McKinney-Vento Homeless Assistance Act
      if start_report(Reports::SystemPerformance::Fy2019::MeasureSix.first)
        set_report_start_and_end()
        # Overview: Returns to homelessness after exit to PH of clients defined by Category 3 (similar to Measure 2 with a smaller sub-set of clients)
        @answers = setup_questions()
        @support = @answers.deep_dup

        Rails.logger.info "Starting report #{@report.report.name}"
        update_report_progress(percent: 1)
        measure_6_a_and_b()
        update_report_progress(percent: 33)
        measure_6c_1()
        update_report_progress(percent: 66)
        measure_6c_2()
        update_report_progress(percent: 99)

        Rails.logger.info @answers
        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end

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

    end

    def measure_6_a_and_b
      project_types = TH + SH + PH

      project_exit_scope = GrdaWarehouse::ServiceHistoryEnrollment.exit.
        hud_project_type(project_types).
        joins(:project).
        where(last_date_in_program: look_back_until..look_forward_until).
        category_3

      # Limit to CoC funded projects
      project_exit_scope = project_exit_scope.coc_funded_in(coc_code: @report.options['coc_code']) if @report.options['coc_code'].present?

      project_exit_scope = add_filters(scope: project_exit_scope)

      project_exits_to_ph = {}
      project_exists_from = {so: [], es: [], th: [], sh: [], ph: []}
      # Loop over exits
      # If we find an exit with a destination in (3, 10, 11, 19, 20, 21, 22, 23, 26, 28)
      # log the earliest instance of each client (first exit to PH)
      project_exits_universe(scope: project_exit_scope).each do |p_exit|
        next if project_exits_to_ph[p_exit[:client_id]].present?

        # inherit destination from HoH if age <= 17 and destination not collected
        destination = destination_for(project_types, p_exit[:client_id], p_exit[:household_id])
        p_exit[:destination] = destination if destination.present?

        project_exits_to_ph[p_exit[:client_id]] = p_exit if permanent_destination?(p_exit[:destination])
      end

      project_exits_to_ph.each do |id, p_exit|
        case p_exit[:project_type].to_i
          when *SO
            project_exists_from[:so] << p_exit
          when *ES
            project_exists_from[:es] << p_exit
          when *TH
            project_exists_from[:th] << p_exit
          when *SH
            project_exists_from[:sh] << p_exit
          when *PH
            project_exists_from[:ph] << p_exit
        end
      end

      @answers[:sixab_b2][:value] = project_exists_from[:so].count
      @answers[:sixab_b3][:value] = project_exists_from[:es].count
      @answers[:sixab_b4][:value] = project_exists_from[:th].count
      @answers[:sixab_b5][:value] = project_exists_from[:sh].count
      @answers[:sixab_b6][:value] = project_exists_from[:ph].count
      @answers[:sixab_b7][:value] = @answers[:sixab_b2][:value] + @answers[:sixab_b3][:value] + @answers[:sixab_b4][:value] + @answers[:sixab_b5][:value] + @answers[:sixab_b6][:value]

      client_personal_ids = personal_ids(project_exit_scope.pluck(:client_id))

      @support[:sixab_b2][:support] = support_for(answer: :sixab_b2, data: project_exists_from[:so], personal_ids: client_personal_ids)
      @support[:sixab_b3][:support] = support_for(answer: :sixab_b3, data: project_exists_from[:es], personal_ids: client_personal_ids)
      @support[:sixab_b4][:support] = support_for(answer: :sixab_b4, data: project_exists_from[:th], personal_ids: client_personal_ids)
      @support[:sixab_b5][:support] = support_for(answer: :sixab_b5, data: project_exists_from[:sh], personal_ids: client_personal_ids)
      @support[:sixab_b6][:support] = support_for(answer: :sixab_b6, data: project_exists_from[:ph], personal_ids: client_personal_ids)

      update_report_progress(percent: 10)

      project_exit_counts = {
        c_0_180_days: {
          so: {counts: [], support: []},
          es: {counts: [], support: []},
          th: {counts: [], support: []},
          sh: {counts: [], support: []},
          ph: {counts: [], support: []},
        },
        e_181_365_days: {
          so: {counts: [], support: []},
          es: {counts: [], support: []},
          th: {counts: [], support: []},
          sh: {counts: [], support: []},
          ph: {counts: [], support: []},
        },
        g_366_730_days: {
          so: {counts: [], support: []},
          es: {counts: [], support: []},
          th: {counts: [], support: []},
          sh: {counts: [], support: []},
          ph: {counts: [], support: []},
        }
      }

      # Step 5
      # Find the next entry date where the project type is ES, SO, SH, and sometimes TH
      # See notes on 5.b and 5.c regarding TH & PH
      return_enrollments = {}
      project_exits_to_ph.each do |client_id, p_exit|
        prior_project_type = project_type_slug(p_exit[:project_type])
        prior_project_exit = p_exit[:last_date_in_program]
        previous_exit_from_ph = p_exit[:last_date_in_program] # use the first exit date initially
        all_entries_for_client(scope: client_scope(p_exit)).each do |entry|
          # find the first instance where the entry is into ES, SO, or SH
          # or, the entry is into TH more than 14 days after p_exit[:last_date_in_program]
          # or, the entry is into PH more than 14 days after p_exit[:last_date_in_program]
          # and more than 14 days after any prior PH exit
          break if return_enrollments[client_id].present?

          project_type = project_type_slug(entry[:project_type])
          entry_date = entry[:first_date_in_program]
          days_since_initial_exit_to_permanent_destination = (entry_date - p_exit[:last_date_in_program]).to_i
          days_since_previous_ph_exit = (entry_date - previous_exit_from_ph).to_i

          if homeless_project?(project_type)
            return_enrollments[client_id] = entry
          elsif project_type == 'TH' && days_since_initial_exit_to_permanent_destination > 14
            return_enrollments[client_id] = entry
          elsif project_type == 'PH' && days_since_previous_ph_exit > 14
            return_enrollments[client_id] = entry
          end
          prior_project_type = project_type
          prior_project_exit = entry[:last_date_in_program]
          # Keep track of most-recent exit from PH
          previous_exit_from_ph = entry[:last_date_in_program] if project_type.in?(['TH', 'PH']) && entry[:last_date_in_program].present?
        end
      end

      # Step 6
      return_enrollments.each do |client_id, entry|
        initial_exit = project_exits_to_ph[client_id]
        day_count = (entry[:first_date_in_program] - initial_exit[:last_date_in_program]).to_i
        # Ignore anyone who's return was over 2 years from leaving
        next if day_count > 730

        project_type = project_type_slug(initial_exit[:project_type]).downcase.to_sym
        day_count_slug = case day_count
          when (0..180)
            :c_0_180_days
          when (181..365)
            :e_181_365_days
          when (367..730)
            :g_366_730_days
          end
        next unless day_count_slug.present?
        next unless project_exit_counts[day_count_slug][project_type].present?

        project_exit_counts[day_count_slug][project_type][:counts] << day_count
        project_exit_counts[day_count_slug][project_type][:support] << [ initial_exit[:client_id], day_count ]
      end

      @answers[:sixab_c2][:value] = project_exit_counts[:c_0_180_days][:so][:counts].size
      @answers[:sixab_c3][:value] = project_exit_counts[:c_0_180_days][:es][:counts].size
      @answers[:sixab_c4][:value] = project_exit_counts[:c_0_180_days][:th][:counts].size
      @answers[:sixab_c5][:value] = project_exit_counts[:c_0_180_days][:sh][:counts].size
      @answers[:sixab_c6][:value] = project_exit_counts[:c_0_180_days][:ph][:counts].size
      @answers[:sixab_e2][:value] = project_exit_counts[:e_181_365_days][:so][:counts].size
      @answers[:sixab_e3][:value] = project_exit_counts[:e_181_365_days][:es][:counts].size
      @answers[:sixab_e4][:value] = project_exit_counts[:e_181_365_days][:th][:counts].size
      @answers[:sixab_e5][:value] = project_exit_counts[:e_181_365_days][:sh][:counts].size
      @answers[:sixab_e6][:value] = project_exit_counts[:e_181_365_days][:ph][:counts].size
      @answers[:sixab_g2][:value] = project_exit_counts[:g_366_730_days][:so][:counts].size
      @answers[:sixab_g3][:value] = project_exit_counts[:g_366_730_days][:es][:counts].size
      @answers[:sixab_g4][:value] = project_exit_counts[:g_366_730_days][:th][:counts].size
      @answers[:sixab_g5][:value] = project_exit_counts[:g_366_730_days][:sh][:counts].size
      @answers[:sixab_g6][:value] = project_exit_counts[:g_366_730_days][:ph][:counts].size

      @support[:sixab_c2][:support] = support_for(answer: :sixab_c2, data: project_exit_counts[:c_0_180_days][:so][:support], personal_ids: client_personal_ids)
      @support[:sixab_c3][:support] = support_for(answer: :sixab_c3, data: project_exit_counts[:c_0_180_days][:es][:support], personal_ids: client_personal_ids)
      @support[:sixab_c4][:support] = support_for(answer: :sixab_c4, data: project_exit_counts[:c_0_180_days][:th][:support], personal_ids: client_personal_ids)
      @support[:sixab_c5][:support] = support_for(answer: :sixab_c5, data: project_exit_counts[:c_0_180_days][:sh][:support], personal_ids: client_personal_ids)
      @support[:sixab_c6][:support] = support_for(answer: :sixab_c6, data: project_exit_counts[:c_0_180_days][:ph][:support], personal_ids: client_personal_ids)
      @support[:sixab_e2][:support] = support_for(answer: :sixab_e2, data: project_exit_counts[:e_181_365_days][:so][:support], personal_ids: client_personal_ids)
      @support[:sixab_e3][:support] = support_for(answer: :sixab_e3, data: project_exit_counts[:e_181_365_days][:es][:support], personal_ids: client_personal_ids)
      @support[:sixab_e4][:support] = support_for(answer: :sixab_e4, data: project_exit_counts[:e_181_365_days][:th][:support], personal_ids: client_personal_ids)
      @support[:sixab_e5][:support] = support_for(answer: :sixab_e5, data: project_exit_counts[:e_181_365_days][:sh][:support], personal_ids: client_personal_ids)
      @support[:sixab_e6][:support] = support_for(answer: :sixab_e6, data: project_exit_counts[:e_181_365_days][:ph][:support], personal_ids: client_personal_ids)
      @support[:sixab_g2][:support] = support_for(answer: :sixab_g2, data: project_exit_counts[:g_366_730_days][:so][:support], personal_ids: client_personal_ids)
      @support[:sixab_g3][:support] = support_for(answer: :sixab_g3, data: project_exit_counts[:g_366_730_days][:es][:support], personal_ids: client_personal_ids)
      @support[:sixab_g4][:support] = support_for(answer: :sixab_g4, data: project_exit_counts[:g_366_730_days][:th][:support], personal_ids: client_personal_ids)
      @support[:sixab_g5][:support] = support_for(answer: :sixab_g5, data: project_exit_counts[:g_366_730_days][:sh][:support], personal_ids: client_personal_ids)
      @support[:sixab_g6][:support] = support_for(answer: :sixab_g6, data: project_exit_counts[:g_366_730_days][:ph][:support], personal_ids: client_personal_ids)
      # simple math
      @answers[:sixab_c7][:value] = @answers[:sixab_c2][:value] + @answers[:sixab_c3][:value] + @answers[:sixab_c4][:value] + @answers[:sixab_c5][:value] + @answers[:sixab_c6][:value]
      @answers[:sixab_e7][:value] = @answers[:sixab_e2][:value] + @answers[:sixab_e3][:value] + @answers[:sixab_e4][:value] + @answers[:sixab_e5][:value] + @answers[:sixab_e6][:value]
      @answers[:sixab_g7][:value] = @answers[:sixab_g2][:value] + @answers[:sixab_g3][:value] + @answers[:sixab_g4][:value] + @answers[:sixab_g5][:value] + @answers[:sixab_g6][:value]

      # @answers[:sixab_d2][:value] = ((@answers[:sixab_c2][:value].to_f / @answers[:sixab_b2][:value]) * 100).round(2)
      # @answers[:sixab_d3][:value] = ((@answers[:sixab_c3][:value].to_f / @answers[:sixab_b3][:value]) * 100).round(2)
      @answers[:sixab_d4][:value] = ((@answers[:sixab_c4][:value].to_f / @answers[:sixab_b4][:value]) * 100).round(2)
      @answers[:sixab_d5][:value] = ((@answers[:sixab_c5][:value].to_f / @answers[:sixab_b5][:value]) * 100).round(2)
      @answers[:sixab_d6][:value] = ((@answers[:sixab_c6][:value].to_f / @answers[:sixab_b6][:value]) * 100).round(2)
      @answers[:sixab_d7][:value] = ((@answers[:sixab_c7][:value].to_f / @answers[:sixab_b7][:value]) * 100).round(2)

      # @answers[:sixab_f2][:value] = ((@answers[:sixab_e2][:value].to_f / @answers[:sixab_b2][:value]) * 100).round(2)
      # @answers[:sixab_f3][:value] = ((@answers[:sixab_e3][:value].to_f / @answers[:sixab_b3][:value]) * 100).round(2)
      @answers[:sixab_f4][:value] = ((@answers[:sixab_e4][:value].to_f / @answers[:sixab_b4][:value]) * 100).round(2)
      @answers[:sixab_f5][:value] = ((@answers[:sixab_e5][:value].to_f / @answers[:sixab_b5][:value]) * 100).round(2)
      @answers[:sixab_f6][:value] = ((@answers[:sixab_e6][:value].to_f / @answers[:sixab_b6][:value]) * 100).round(2)
      @answers[:sixab_f7][:value] = ((@answers[:sixab_e7][:value].to_f / @answers[:sixab_b7][:value]) * 100).round(2)

      # @answers[:sixab_h2][:value] = ((@answers[:sixab_g2][:value].to_f / @answers[:sixab_b2][:value]) * 100).round(2)
      # @answers[:sixab_h3][:value] = ((@answers[:sixab_g3][:value].to_f / @answers[:sixab_b3][:value]) * 100).round(2)
      @answers[:sixab_h4][:value] = ((@answers[:sixab_g4][:value].to_f / @answers[:sixab_b4][:value]) * 100).round(2)
      @answers[:sixab_h5][:value] = ((@answers[:sixab_g5][:value].to_f / @answers[:sixab_b5][:value]) * 100).round(2)
      @answers[:sixab_h6][:value] = ((@answers[:sixab_g6][:value].to_f / @answers[:sixab_b6][:value]) * 100).round(2)
      @answers[:sixab_h7][:value] = ((@answers[:sixab_g7][:value].to_f / @answers[:sixab_b7][:value]) * 100).round(2)

      # @answers[:sixab_i2][:value] = @answers[:sixab_c2][:value] + @answers[:sixab_e2][:value] + @answers[:sixab_g2][:value]
      # @answers[:sixab_i3][:value] = @answers[:sixab_c3][:value] + @answers[:sixab_e3][:value] + @answers[:sixab_g3][:value]
      @answers[:sixab_i4][:value] = @answers[:sixab_c4][:value] + @answers[:sixab_e4][:value] + @answers[:sixab_g4][:value]
      @answers[:sixab_i5][:value] = @answers[:sixab_c5][:value] + @answers[:sixab_e5][:value] + @answers[:sixab_g5][:value]
      @answers[:sixab_i6][:value] = @answers[:sixab_c6][:value] + @answers[:sixab_e6][:value] + @answers[:sixab_g6][:value]
      @answers[:sixab_i7][:value] = @answers[:sixab_c7][:value] + @answers[:sixab_e7][:value] + @answers[:sixab_g7][:value]

      # @answers[:sixab_j2][:value] = ((@answers[:sixab_i2][:value].to_f / @answers[:sixab_b2][:value]) * 100).round(2)
      # @answers[:sixab_j3][:value] = ((@answers[:sixab_i3][:value].to_f / @answers[:sixab_b3][:value]) * 100).round(2)
      @answers[:sixab_j4][:value] = ((@answers[:sixab_i4][:value].to_f / @answers[:sixab_b4][:value]) * 100).round(2)
      @answers[:sixab_j5][:value] = ((@answers[:sixab_i5][:value].to_f / @answers[:sixab_b5][:value]) * 100).round(2)
      @answers[:sixab_j6][:value] = ((@answers[:sixab_i6][:value].to_f / @answers[:sixab_b6][:value]) * 100).round(2)
      @answers[:sixab_j7][:value] = ((@answers[:sixab_i7][:value].to_f / @answers[:sixab_b7][:value]) * 100).round(2)
      return @answers
    end

    def permanent_destination?(dest)
      PERMANENT_DESTINATIONS.include?(dest)
    end

    def look_back_until
      if LOOKBACK_STOP_DATE.to_date >= (@report_start - 730.days)
        LOOKBACK_STOP_DATE
      else
        (@report_start - 730.days).strftime('%Y-%m-%d')
      end
    end

    def look_forward_until
      (@report_end - 730.days).strftime('%Y-%m-%d')
    end

    def columns
      @columns ||= {
        client_id: :client_id,
        destination: :destination,
        date: :date,
        first_date_in_program: :first_date_in_program,
        last_date_in_program: :last_date_in_program,
        project_type: :computed_project_type,
        project_id: :project_id,
        data_source_id: :data_source_id,
        project_name: :project_name,
        household_id: :household_id,
      }
    end

    def project_type_slug(project_type_id)
      case project_type_id
      when *SO
          'SO'
      when *ES
        'ES'
      when *TH
        'TH'
      when *SH
        'SH'
      when *PH
        'PH'
      end
    end

    def homeless_project?(project_type)
      project_type.in?(['ES', 'SO', 'SH'])
    end

    def project_exits_universe(scope: )
      scope.order(client_id: :asc, last_date_in_program: :asc).
        select(*columns.values).
        pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end
    end

    def all_entries_for_client(scope:)
      scope.order(first_date_in_program: :asc).
        pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end
    end

    def client_scope(enrollment)
      # need to move this to get (exit_date > entry_date <= report_end)
      start_date = enrollment[:last_date_in_program] + 1.day
      scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
        joins(:project).
        where(client_id: enrollment[:client_id]).
        where(first_date_in_program: (start_date..@report_end))

      add_filters(scope: scope)
    end

    def measure_6c_1
      # Select clients who have a recorded stay in  SH, TH and PH-RRH during the report period and who are Category 3
      # who also don't have an ongoing enrollment at an SH, TH and PH-RRH on the final day of the report
      # eg. Those who were counted by SH, TH and PH-RRH, but exited to somewhere else

      client_id_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
          ongoing(on_date: @report.options['report_end']).
          hud_project_type(SH + TH + RRH + PH)

      client_id_scope = add_filters(scope: client_id_scope)

      universe_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
        category_3.
        open_between(start_date: @report_start,
          end_date: @report_end + 1.day).
        hud_project_type(SH + TH). # RRH is in PH below
        where.not(client_id: client_id_scope.
          select(:client_id).
          distinct
        )

      ph_without_move_in_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
          category_3.
          open_between(start_date: @report_start,
              end_date: @report_end + 1.day).
          hud_project_type(PH).
          joins(:enrollment).
          where(
              e_t[:MoveInDate].eq(nil).or(e_t[:MoveInDate].gt(@report_end))
          ).
          where.not(client_id: client_id_scope.
            select(:client_id).
            distinct
          )

      universe_scope = add_filters(scope: universe_scope)
      ph_without_move_in_scope = add_filters(scope: ph_without_move_in_scope)

      universe = universe_scope.
        select(:client_id).
        distinct.
        pluck(:client_id)

      universe += ph_without_move_in_scope.
        distinct.
        pluck(:client_id)

      destinations = {}
      universe.each do |id|
        destination_scope = GrdaWarehouse::ServiceHistoryEnrollment.exit.
          ended_between(start_date: @report_start,
          end_date: @report_end + 1.day).
          hud_project_type(SH + TH + RRH + PH).
          where(client_id: id)

        destination_scope = add_filters(scope: destination_scope)

        destinations[id] = destination_scope.
          order(date: :desc).
          limit(1).
          pluck(:destination).first
      end

      client_personal_ids = personal_ids(universe)

      remaining_leavers = destinations.reject{ |id, destination| [15, 6,25,24].include?(destination.to_i)}
      @answers[:sixc1_c2][:value] = remaining_leavers.size
      @support[:sixc1_c2][:support] = {
        headers: ['Client ID', 'Personal IDs', 'Destination'],
        counts: remaining_leavers.map do |id, destination|
          [
            id,
            client_personal_ids[id].join(', '),
            HUD.destination(destination),
          ]
        end
      }

      permanent_leavers = destinations.select{ |id, destination| [26, 11, 21, 3, 10, 28, 20, 19, 22, 23].include?(destination.to_i)}
      @answers[:sixc1_c3][:value] = permanent_leavers.size
      @support[:sixc1_c3][:support] = {
        headers: ['Client ID', 'Personal IDs', 'Destination'],
        counts: permanent_leavers.map do |id, destination|
          [
            id,
            client_personal_ids[id].join(', '),
            HUD.destination(destination),
          ]
        end
      }
      @answers[:sixc1_c4][:value] = ((@answers[:sixc1_c3][:value].to_f / @answers[:sixc1_c2][:value]) * 100).round(2)
      return @answers
    end

    def measure_6c_2
      # Select clients who have a recorded stay in PH but not PH-RRH during the report period
      # who also don't have an ongoing enrollment at a PH but not PH-RRH on the final day of the report
      # eg. Those who were counted by PH but not PH-RRH, but exited to somewhere else

      client_id_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
          ongoing(on_date: @report_end).
          hud_project_type(PH_PSH)

      client_id_scope = add_filters(scope: client_id_scope)

      leavers_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
        category_3.
        open_between(start_date: @report_start,
        end_date: @report_end + 1.day).
        hud_project_type(PH_PSH).
        joins(:enrollment).
        where(
          e_t[:MoveInDate].not_eq(nil).and(e_t[:MoveInDate].lteq(@report_end))
        ).
        where.not(client_id: client_id_scope.
          select(:client_id).
          distinct
        )

      if @report.options['coc_code'].present?
        leavers_scope = leavers_scope.coc_funded_in(coc_code: @report.options['coc_code'])
      end

      leavers_scope = add_filters(scope: leavers_scope)

      leavers = leavers_scope.
        select(:client_id).
        distinct.
        pluck(:client_id)

      stayers_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
        category_3.
        ongoing(on_date: @report_end).
        hud_project_type(PH_PSH).
        joins(:enrollment).
        where(
          e_t[:MoveInDate].eq(nil).or(e_t[:MoveInDate].gt(@report_end))
        )

      if @report.options['coc_code'].present?
        stayers_scope = stayers_scope.coc_funded_in(coc_code: @report.options['coc_code'])
      end

      stayers_scope = add_filters(scope: stayers_scope)

      stayers = stayers_scope.
        select(:client_id).
        distinct.
        pluck(:client_id)

      destinations = {}
      leavers.each do |id|
        destination_scope = GrdaWarehouse::ServiceHistoryEnrollment.exit.
          ended_between(start_date: @report_start,
          end_date: @report_end + 1.day).
          hud_project_type(PH).
          where(client_id: id)

        if @report.options['coc_code'].present?
          destination_scope = destination_scope.coc_funded_in(coc_code: @report.options['coc_code'])
        end

        destination_scope = add_filters(scope: destination_scope)

        destinations[id] = destination_scope.
          order(date: :desc).
          limit(1).
          pluck(:destination).first
      end

      client_personal_ids = personal_ids(leavers)

      remaining_leavers = destinations.reject{ |id, destination| [15, 6, 25, 24].include?(destination.to_i)}
      @answers[:sixc2_c2][:value] = remaining_leavers.size + stayers.size
      @support[:sixc2_c2][:support] = {
        headers: ['Client ID', 'Personal IDs', 'Destination'],
        counts: remaining_leavers.map do |id, destination|
          [
            id,
            client_personal_ids[id].join(', '),
            HUD.destination(destination),
          ]
        end
      }

      permanent_leavers = destinations.select{ |id, destination| [26, 11, 21, 3, 10, 28, 20, 19, 22, 23].include?(destination.to_i)}
      @answers[:sixc2_c3][:value] = permanent_leavers.size + stayers.size
      @support[:sixc2_c3][:support] = {
        headers: ['Client ID', 'Personal IDs', 'Destination'],
        counts: permanent_leavers.map{|id, destination| [id, HUD.destination(destination)]},
      }
      @answers[:sixc2_c4][:value] = ((@answers[:sixc2_c3][:value].to_f / @answers[:sixc2_c2][:value]) * 100).round(2)
      return @answers
    end

    def support_for(answer:, data:, personal_ids:)
      case answer
      when :sixab_b2, :sixab_b3, :sixab_b4, :sixab_b5, :sixab_b6
        {
          headers: ['Client ID', 'Personal IDs', 'Project Name'],
          counts: data.map do |m|
            [
              m[:client_id],
              personal_ids[m[:client_id]].join(', '),
              m[:project_name],
            ]
          end
        }
      when :sixab_c2, :sixab_c3, :sixab_c4, :sixab_c5, :sixab_c6, :sixab_e2, :sixab_e3, :sixab_e4, :sixab_e5, :sixab_e6, :sixab_g2, :sixab_g3, :sixab_g4, :sixab_g5, :sixab_g6
        {
          headers: ['Client ID', 'Personal IDs', 'Days'],
          counts: data,
        }
      else
        raise NotImplementedError
      end
    end

    def children_without_destination(project_types)
      # 99 = Not collected
      destination_not_collected = [99]

      @child_ids ||= {}
      @child_ids[project_types] ||= begin
        child_candidates_scope =  GrdaWarehouse::ServiceHistoryEnrollment.entry.
            category_3. # this differentiates this from the version in Measure 2
            hud_project_type(project_types).
            open_between(start_date: @report_start - 1.day, end_date: @report_end).
            with_service_between(start_date: @report_start - 1.day, end_date: @report_end).
            joins(:enrollment, :client).
            where(
              she_t[:destination].in(destination_not_collected).or(she_t[:destination].eq(nil)),
              c_t[:DOB].not_eq(nil).and(c_t[:DOB].lteq(@report_start - 17.years)),
            ).
            distinct.
            select(:client_id)

        child_candidates = add_filters(scope: child_candidates_scope).
            pluck(:client_id, c_t[:DOB], e_t[:EntryDate], :age, :head_of_household_id, :household_id)


        child_id_to_destination = {}
        child_candidates.each do |(client_id, dob, entry_date, age, hoh_id, household_id)|
          age = age_for_report dob: dob, entry_date: entry_date, age: age
          if age.present? && age <= 17
            child_id_to_destination[[client_id, household_id]] = hoh_destination_for(project_types, hoh_id, household_id)
          end
        end
        child_id_to_destination
      end
    end

    def hoh_destinations(project_types)
      @hoh_destinations ||= {}
      @hoh_destinations[project_types] ||= begin
        GrdaWarehouse::ServiceHistoryEnrollment.exit.
          category_3. # this differentiates this from the version in Measure 2
          hud_project_type(project_types).
          open_between(start_date: @report_start - 1.day, end_date: @report_end).
          with_service_between(start_date: @report_start - 1.day, end_date: @report_end).
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

    def destination_for(project_types, client_id, household_id)
      children_without_destination(project_types)[[client_id, household_id]]
    end

    def setup_questions
      {
        sixab_a2: {
          title:  nil,
          value: 'Total number of persons who exited to a permanent housing destination; exit was from SO',
        },
        sixab_a3: {
          title: nil,
          value: 'Total number of persons who exited to a permanent housing destination; exit was from ES',
        },
        sixab_a4: {
          title: nil,
          value: 'Total number of persons who exited to a permanent housing destination; exit was from TH',
        },
        sixab_a5: {
          title: nil,
          value: 'Total number of persons who exited to a permanent housing destination; exit was from SH',
        },
        sixab_a6: {
          title: nil,
          value: 'Total number of persons who exited to a permanent housing destination; exit was from PH',
        },
        sixab_a7: {
          title: nil,
          value: 'Total number of persons who exited to a permanent housing destination; Total retuns to homelessness',
        },
        sixab_b1: {
          title: nil,
          value: 'Total Number of Persons who Exited to a Permanent Housing Destination (2 Years Prior)',
        },
        sixab_b2: {
          title: 'Total number of persons who exited to a permanent housing destination; exit was from SO (2 years prior)',
          value: 0,
        },
        sixab_b3: {
          title: 'Total number of persons who exited to a permanent housing destination; exit was from ES (2 years prior)',
          value: 0,
        },
        sixab_b4: {
          title: 'Total number of persons who exited to a permanent housing destination; exit was from TH (2 years prior)',
          value: 0,
        },
        sixab_b5: {
          title: 'Total number of persons who exited to a permanent housing destination; exit was from SH (2 years prior)',
          value: 0,
        },
        sixab_b6: {
          title: 'Total number of persons who exited to a permanent housing destination; exit was from PH (2 years prior)',
          value: 0,
        },
        sixab_b7: {
          title: 'Total number of persons who exited to a permanent housing destination; Total retuns to homelessness (2 years prior)',
          value: 0,
        },
        sixab_c1: {
          title: nil,
          value: 'Number Returning to Homelessness in Less than 6 Months (0 - 180 days)',
        },
        sixab_c2: {
          title: 'Number returing to homelessness in less than 6 months; exit was from SO (0-180 days) ',
          value: 0,
        },
        sixab_c3: {
          title: 'Number returing to homelessness in less than 6 months; exit was from ES (0-180 days) ',
          value: 0,
        },
        sixab_c4: {
          title: 'Number returing to homelessness in less than 6 months; exit was from TH (0-180 days) ',
          value: 0,
        },
        sixab_c5: {
          title: 'Number returing to homelessness in less than 6 months; exit was from SH (0-180 days) ',
          value: 0,
        },
        sixab_c6: {
          title: 'Number returing to homelessness in less than 6 months; exit was from PH (0-180 days) ',
          value: 0,
        },
        sixab_c7: {
          title: 'Number returing to homelessness in less than 6 months; Total retuns to homelessness (0-180 days) ',
          value: 0,
        },
        sixab_d1: {
          title: nil,
          value: 'Percentage of Returns in Less than 6 Months (0 - 180 days)',
        },
        sixab_d2: {
          title: 'Percentage of returns in less than 6 months; exit was from SO (0-180 days)',
          value: 0,
        },
        sixab_d3: {
          title: 'Percentage of returns in less than 6 months; exit was from ES (0-180 days)',
          value: 0,
        },
        sixab_d4: {
          title: 'Percentage of returns in less than 6 months; exit was from TH (0-180 days)',
          value: 0,
        },
        sixab_d5: {
          title: 'Percentage of returns in less than 6 months; exit was from SH (0-180 days)',
          value: 0,
        },
        sixab_d6: {
          title: 'Percentage of returns in less than 6 months; exit was from PH (0-180 days)',
          value: 0,
        },
        sixab_d7: {
          title: 'Percentage of returns in less than 6 months; Total retuns to homelessness (0-180 days)',
          value: 0,
        },
        sixab_e1: {
          title: nil,
          value: 'Number Returning to Homelessness from 6 to 12 Months (181 - 365 days)',
        },
        sixab_e2: {
          title: 'Number returning to homelessness from 6 to 12 months; exit was from SO (181-365 days)',
          value: 0,
        },
        sixab_e3: {
          title: 'Number returning to homelessness from 6 to 12 months; exit was from ES (181-365 days)',
          value: 0,
        },
        sixab_e4: {
          title: 'Number returning to homelessness from 6 to 12 months; exit was from TH (181-365 days)',
          value: 0,
        },
        sixab_e5: {
          title: 'Number returning to homelessness from 6 to 12 months; exit was from SH (181-365 days)',
          value: 0,
        },
        sixab_e6: {
          title: 'Number returning to homelessness from 6 to 12 months; exit was from PH (181-365 days)',
          value: 0,
        },
        sixab_e7: {
          title: 'Number returning to homelessness from 6 to 12 months; Total retuns to homelessness (181-365 days)',
          value: 0,
        },
        sixab_f1: {
          title: nil,
          value: 'Percentage of Returns from 6 to 12 Months (181 - 365 days)',
        },
        sixab_f2: {
          title: 'Percentage of returns from 6 to 12 months; exit was from SO (181-365 days)',
          value: 0,
        },
        sixab_f3: {
          title: 'Percentage of returns from 6 to 12 months; exit was from ES (181-365 days)',
          value: 0,
        },
        sixab_f4: {
          title: 'Percentage of returns from 6 to 12 months; exit was from TH (181-365 days)',
          value: 0,
        },
        sixab_f5: {
          title: 'Percentage of returns from 6 to 12 months; exit was from SH (181-365 days)',
          value: 0,
        },
        sixab_f6: {
          title: 'Percentage of returns from 6 to 12 months; exit was from PH (181-365 days)',
          value: 0,
        },
        sixab_f7: {
          title: 'Percentage of returns from 6 to 12 months; Total retuns to homelessness (181-365 days)',
          value: 0,
        },
        sixab_g1: {
          title: nil,
          value: 'Number Returning to Homelessness from 13 to 24 Months (366 - 730 days)',
        },
        sixab_g2: {
          title: 'Number returning to homelessness from 13 to 24 months; exit was from SO (366-730 days)',
          value: 0,
        },
        sixab_g3: {
          title: 'Number returning to homelessness from 13 to 24 months; exit was from ES (366-730 days)',
          value: 0,
        },
        sixab_g4: {
          title: 'Number returning to homelessness from 13 to 24 months; exit was from TH (366-730 days)',
          value: 0,
        },
        sixab_g5: {
          title: 'Number returning to homelessness from 13 to 24 months; exit was from SH (366-730 days)',
          value: 0,
        },
        sixab_g6: {
          title: 'Number returning to homelessness from 13 to 24 months; exit was from PH (366-730 days)',
          value: 0,
        },
        sixab_g7: {
          title: 'Number returning to homelessness from 13 to 24 months; Total retuns to homelessness (366-730 days)',
          value: 0,
        },
        sixab_h1: {
          title: nil,
          value: 'Percentage of Returns from 13 to 24 Months (366 - 730 days)',
        },
        sixab_h2: {
          title: 'Percentage of returns from 13 to 24 months; exit was from SO (366-730 days)',
          value: 0,
        },
        sixab_h3: {
          title: 'Percentage of returns from 13 to 24 months; exit was from ES (366-730 days)',
          value: 0,
        },
        sixab_h4: {
          title: 'Percentage of returns from 13 to 24 months; exit was from TH (366-730 days)',
          value: 0,
        },
        sixab_h5: {
          title: 'Percentage of returns from 13 to 24 months; exit was from SH (366-730 days)',
          value: 0,
        },
        sixab_h6: {
          title: 'Percentage of returns from 13 to 24 months; exit was from PH (366-730 days)',
          value: 0,
        },
        sixab_h7: {
          title: 'Percentage of returns from 13 to 24 months; Total retuns to homelessness (366-730 days)',
          value: 0,
        },
        sixab_i1: {
          title: nil,
          value: 'Number of Returns in 2 Years',
        },
        sixab_i2: {
          title: 'Number of returns in 2 years; exit was from SO',
          value: 0,
        },
        sixab_i3: {
          title: 'Number of returns in 2 years; exit was from ES',
          value: 0,
        },
        sixab_i4: {
          title: 'Number of returns in 2 years; exit was from TH',
          value: 0,
        },
        sixab_i5: {
          title: 'Number of returns in 2 years; exit was from SH',
          value: 0,
        },
        sixab_i6: {
          title: 'Number of returns in 2 years; exit was from PH',
          value: 0,
        },
        sixab_i7: {
          title: 'Number of returns in 2 years; Total retuns to homelessness',
          value: 0,
        },
        sixab_j1: {
          title: nil,
          value: 'Percentage of Returns in 2 Years',
        },
        sixab_j2: {
          title: 'Percentage of returns in 2 years; exit was from SO',
          value: 0,
        },
        sixab_j3: {
          title: 'Percentage of returns in 2 years; exit was from ES',
          value: 0,
        },
        sixab_j4: {
          title: 'Percentage of returns in 2 years; exit was from TH',
          value: 0,
        },
        sixab_j5: {
          title: 'Percentage of returns in 2 years; exit was from SH',
          value: 0,
        },
        sixab_j6: {
          title: 'Percentage of returns in 2 years; exit was from PH',
          value: 0,
        },
        sixab_j7: {
          title: 'Percentage of returns in 2 years; Total retuns to homelessness',
          value: 0,
        },
        sixc1_a2: {
          title:  nil,
          value: 'Universe: Cat. 3 SH, TH and PH-RRH system leavers',
        },
        sixc1_a3: {
          title: nil,
          value: 'Of the persons above, those who exited to permanent destinations',
        },
        sixc1_a4: {
          title: nil,
          value: '% successful exits',
        },
        sixc1_b1: {
          title: nil,
          value: 'Previous FY',
        },
        sixc1_b2: {
          title: 'Universe: Cat. 3 SH, TH and PH-RRH system leavers (previous FY)',
          value: 0,
        },
        sixc1_b3: {
          title: 'Of the persons above, those who exited to permanent destinations (previous FY)',
          value: 0,
        },
        sixc1_b4: {
          title: '% successful exits (previous FY)',
          value: 0,
        },
        sixc1_c1: {
          title: nil,
          value: 'Current FY',
        },
        sixc1_c2: {
          title: 'Universe: Cat. 3 SH, TH and PH-RRH system leavers (current FY)',
          value: 0,
        },
        sixc1_c3: {
          title: 'Of the persons above, those who exited to permanent destinations (current FY)',
          value: 0,
        },
        sixc1_c4: {
          title: '% successful exits (current FY)',
          value: 0,
        },
        sixc1_d1: {
          title: nil,
          value: 'Difference',
        },
        sixc1_d2: {
          title: 'Universe: Cat. 3 SH, TH and PH-RRH system leavers (difference)',
          value: 0,
        },
        sixc1_d3: {
          title: 'Of the persons above, those who exited to permanent destinations (difference)',
          value: 0,
        },
        sixc1_d4: {
          title: '% successful exits (difference)',
          value: 0,
        },
        sixc2_a2: {
          title:  nil,
          value: 'Universe: Cat. 3 PH-PSH system stayers and leavers',
        },
        sixc2_a3: {
          title: nil,
          value: 'Of persons above, count those who remained in PH-PSH projects and those who exited to permanent housing destinations',
        },
        sixc2_a4: {
          title: nil,
          value: '% successful exits',
        },
        sixc2_b1: {
          title: nil,
          value: 'Previous FY',
        },
        sixc2_b2: {
          title: 'Universe: Cat. 3 PH-PSH system stayers and leavers (previous FY)',
          value: 0,
        },
        sixc2_b3: {
          title: 'Of persons above, count those who remained in PH-PSH projects and those who exited to permanent housing destinations (previous FY)',
          value: 0,
        },
        sixc2_b4: {
          title: '% Successul exits/retention (previous FY)',
          value: 0,
        },
        sixc2_c1: {
          title: nil,
          value: 'Current FY',
        },
        sixc2_c2: {
          title: 'Universe: Cat. 3 PH-PSH system stayers and leavers (current FY)',
          value: 0,
        },
        sixc2_c3: {
          title: 'Of persons above, count those who remained in PH-PSH projects and those who exited to permanent housing destinations (current FY)',
          value: 0,
        },
        sixc2_c4: {
          title: '% Successul exits/retention (current FY)',
          value: 0,
        },
        sixc2_d1: {
          title: nil,
          value: 'Difference',
        },
        sixc2_d2: {
          title: 'Universe: Cat. 3 PH-PSH system stayers and leavers (difference)',
          value: 0,
        },
        sixc2_d3: {
          title: 'Of persons above, count those who remained in PH-PSH projects and those who exited to permanent housing destinations (difference)',
          value: 0,
        },
        sixc2_d4: {
          title: '% Successul exits/retention (difference)',
          value: 0,
        },
      }
    end
  end
end
