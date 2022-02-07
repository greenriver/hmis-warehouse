###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ReportGenerators::SystemPerformance::Fy2019
  class MeasureTwo < Base
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

    PERMANENT_DESTINATIONS = [26, 11, 21, 3, 10, 28, 20, 19, 22, 23, 31, 33, 34]
    TEMPORARY_DESTINATIONS = [1, 15, 6, 14, 7, 27, 16, 4, 29, 18, 12, 13, 5, 2, 25, 32]

    def run!
      # Disable logging so we don't fill the disk
      # ActiveRecord::Base.logger.silence do
        calculate()
      # end # End silence ActiveRecord Log
    end

    def calculate
      if start_report(Reports::SystemPerformance::Fy2019::MeasureTwo.first)
        set_report_start_and_end()
        Rails.logger.info "Starting report #{@report.report.name}"

        @answers = setup_questions()
        @support = @answers.deep_dup
        # Overview: Calculate return to homelessness after exit to permanent housing

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

        project_types = SO + ES + TH + SH + PH

        # Step 1
        project_exit_scope = GrdaWarehouse::ServiceHistoryEnrollment.exit.
          hud_project_type(project_types).
          joins(:project).
          where(last_date_in_program: look_back_until..look_forward_until)

        project_exit_scope = add_filters(scope: project_exit_scope)

        project_exits_to_ph = {}
        project_exists_from = {so: [], es: [], th: [], sh: [], ph: []}
        # Step 2
        # If we find an exit with a destination to PH (3, 10, 11, 19, 20, 21, 22, 23, 26, 28)
        # log the earliest instance of each client (first exit to PH)
        project_exits_universe(scope: project_exit_scope).each do |p_exit|
          next if project_exits_to_ph[p_exit[:client_id]].present?

          # inherit destination from HoH if age <= 17 and destination not collected
          destination = destination_for(project_types, p_exit[:client_id], p_exit[:household_id])
          p_exit[:destination] = destination if destination.present?

          project_exits_to_ph[p_exit[:client_id]] = p_exit if permanent_destination?(p_exit[:destination])
        end

        # Step 3
        # Count earliest exits to a permanent destination from a particular project type
        project_exits_to_ph.each do |_, p_exit|
          case p_exit[:project_type]
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

        @client_personal_ids = personal_ids(project_exit_scope.distinct.pluck(:client_id))

        @answers[:two_b2][:value] = project_exists_from[:so].size
        @support[:two_b2][:support] = support_for(answer: :two_b2, data: project_exists_from[:so])
        @answers[:two_b3][:value] = project_exists_from[:es].size
        @support[:two_b3][:support] = support_for(answer: :two_b3, data: project_exists_from[:es])
        @answers[:two_b4][:value] = project_exists_from[:th].size
        @support[:two_b4][:support] = support_for(answer: :two_b4, data: project_exists_from[:th])
        @answers[:two_b5][:value] = project_exists_from[:sh].size
        @support[:two_b5][:support] = support_for(answer: :two_b5, data: project_exists_from[:sh])
        @answers[:two_b6][:value] = project_exists_from[:ph].size
        @support[:two_b6][:support] = support_for(answer: :two_b6, data: project_exists_from[:ph])
        # Step 4
        @answers[:two_b7][:value] = @answers[:two_b2][:value] + @answers[:two_b3][:value] + @answers[:two_b4][:value] + @answers[:two_b5][:value] + @answers[:two_b6][:value]

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

        # Step 7
        @answers[:two_c2][:value] = project_exit_counts[:c_0_180_days][:so][:counts].size
        @answers[:two_c3][:value] = project_exit_counts[:c_0_180_days][:es][:counts].size
        @answers[:two_c4][:value] = project_exit_counts[:c_0_180_days][:th][:counts].size
        @answers[:two_c5][:value] = project_exit_counts[:c_0_180_days][:sh][:counts].size
        @answers[:two_c6][:value] = project_exit_counts[:c_0_180_days][:ph][:counts].size
        @answers[:two_e2][:value] = project_exit_counts[:e_181_365_days][:so][:counts].size
        @answers[:two_e3][:value] = project_exit_counts[:e_181_365_days][:es][:counts].size
        @answers[:two_e4][:value] = project_exit_counts[:e_181_365_days][:th][:counts].size
        @answers[:two_e5][:value] = project_exit_counts[:e_181_365_days][:sh][:counts].size
        @answers[:two_e6][:value] = project_exit_counts[:e_181_365_days][:ph][:counts].size
        @answers[:two_g2][:value] = project_exit_counts[:g_366_730_days][:so][:counts].size
        @answers[:two_g3][:value] = project_exit_counts[:g_366_730_days][:es][:counts].size
        @answers[:two_g4][:value] = project_exit_counts[:g_366_730_days][:th][:counts].size
        @answers[:two_g5][:value] = project_exit_counts[:g_366_730_days][:sh][:counts].size
        @answers[:two_g6][:value] = project_exit_counts[:g_366_730_days][:ph][:counts].size

        @support[:two_c2][:support] = support_for(answer: :two_c2, data: project_exit_counts[:c_0_180_days][:so][:support])
        @support[:two_c3][:support] = support_for(answer: :two_c3, data: project_exit_counts[:c_0_180_days][:es][:support])
        @support[:two_c4][:support] = support_for(answer: :two_c4, data: project_exit_counts[:c_0_180_days][:th][:support])
        @support[:two_c5][:support] = support_for(answer: :two_c5, data: project_exit_counts[:c_0_180_days][:sh][:support])
        @support[:two_c6][:support] = support_for(answer: :two_c6, data: project_exit_counts[:c_0_180_days][:ph][:support])
        @support[:two_e2][:support] = support_for(answer: :two_e2, data: project_exit_counts[:e_181_365_days][:so][:support])
        @support[:two_e3][:support] = support_for(answer: :two_e3, data: project_exit_counts[:e_181_365_days][:es][:support])
        @support[:two_e4][:support] = support_for(answer: :two_e4, data: project_exit_counts[:e_181_365_days][:th][:support])
        @support[:two_e5][:support] = support_for(answer: :two_e5, data: project_exit_counts[:e_181_365_days][:sh][:support])
        @support[:two_e6][:support] = support_for(answer: :two_e6, data: project_exit_counts[:e_181_365_days][:ph][:support])
        @support[:two_g2][:support] = support_for(answer: :two_g2, data: project_exit_counts[:g_366_730_days][:so][:support])
        @support[:two_g3][:support] = support_for(answer: :two_g3, data: project_exit_counts[:g_366_730_days][:es][:support])
        @support[:two_g4][:support] = support_for(answer: :two_g4, data: project_exit_counts[:g_366_730_days][:th][:support])
        @support[:two_g5][:support] = support_for(answer: :two_g5, data: project_exit_counts[:g_366_730_days][:sh][:support])
        @support[:two_g6][:support] = support_for(answer: :two_g6, data: project_exit_counts[:g_366_730_days][:ph][:support])

        # Step 8
        # simple math
        @answers[:two_c7][:value] = @answers[:two_c2][:value] + @answers[:two_c3][:value] + @answers[:two_c4][:value] + @answers[:two_c5][:value] + @answers[:two_c6][:value]
        @answers[:two_e7][:value] = @answers[:two_e2][:value] + @answers[:two_e3][:value] + @answers[:two_e4][:value] + @answers[:two_e5][:value] + @answers[:two_e6][:value]
        @answers[:two_g7][:value] = @answers[:two_g2][:value] + @answers[:two_g3][:value] + @answers[:two_g4][:value] + @answers[:two_g5][:value] + @answers[:two_g6][:value]

        # Step 9
        @answers[:two_d2][:value] = ((@answers[:two_c2][:value].to_f / @answers[:two_b2][:value]) * 100).round(2)
        @answers[:two_d3][:value] = ((@answers[:two_c3][:value].to_f / @answers[:two_b3][:value]) * 100).round(2)
        @answers[:two_d4][:value] = ((@answers[:two_c4][:value].to_f / @answers[:two_b4][:value]) * 100).round(2)
        @answers[:two_d5][:value] = ((@answers[:two_c5][:value].to_f / @answers[:two_b5][:value]) * 100).round(2)
        @answers[:two_d6][:value] = ((@answers[:two_c6][:value].to_f / @answers[:two_b6][:value]) * 100).round(2)
        @answers[:two_d7][:value] = ((@answers[:two_c7][:value].to_f / @answers[:two_b7][:value]) * 100).round(2)

        @answers[:two_f2][:value] = ((@answers[:two_e2][:value].to_f / @answers[:two_b2][:value]) * 100).round(2)
        @answers[:two_f3][:value] = ((@answers[:two_e3][:value].to_f / @answers[:two_b3][:value]) * 100).round(2)
        @answers[:two_f4][:value] = ((@answers[:two_e4][:value].to_f / @answers[:two_b4][:value]) * 100).round(2)
        @answers[:two_f5][:value] = ((@answers[:two_e5][:value].to_f / @answers[:two_b5][:value]) * 100).round(2)
        @answers[:two_f6][:value] = ((@answers[:two_e6][:value].to_f / @answers[:two_b6][:value]) * 100).round(2)
        @answers[:two_f7][:value] = ((@answers[:two_e7][:value].to_f / @answers[:two_b7][:value]) * 100).round(2)

        @answers[:two_h2][:value] = ((@answers[:two_g2][:value].to_f / @answers[:two_b2][:value]) * 100).round(2)
        @answers[:two_h3][:value] = ((@answers[:two_g3][:value].to_f / @answers[:two_b3][:value]) * 100).round(2)
        @answers[:two_h4][:value] = ((@answers[:two_g4][:value].to_f / @answers[:two_b4][:value]) * 100).round(2)
        @answers[:two_h5][:value] = ((@answers[:two_g5][:value].to_f / @answers[:two_b5][:value]) * 100).round(2)
        @answers[:two_h6][:value] = ((@answers[:two_g6][:value].to_f / @answers[:two_b6][:value]) * 100).round(2)
        @answers[:two_h7][:value] = ((@answers[:two_g7][:value].to_f / @answers[:two_b7][:value]) * 100).round(2)

        @answers[:two_i2][:value] = @answers[:two_c2][:value] + @answers[:two_e2][:value] + @answers[:two_g2][:value]
        @answers[:two_i3][:value] = @answers[:two_c3][:value] + @answers[:two_e3][:value] + @answers[:two_g3][:value]
        @answers[:two_i4][:value] = @answers[:two_c4][:value] + @answers[:two_e4][:value] + @answers[:two_g4][:value]
        @answers[:two_i5][:value] = @answers[:two_c5][:value] + @answers[:two_e5][:value] + @answers[:two_g5][:value]
        @answers[:two_i6][:value] = @answers[:two_c6][:value] + @answers[:two_e6][:value] + @answers[:two_g6][:value]
        @answers[:two_i7][:value] = @answers[:two_c7][:value] + @answers[:two_e7][:value] + @answers[:two_g7][:value]

        @answers[:two_j2][:value] = ((@answers[:two_i2][:value].to_f / @answers[:two_b2][:value]) * 100).round(2)
        @answers[:two_j3][:value] = ((@answers[:two_i3][:value].to_f / @answers[:two_b3][:value]) * 100).round(2)
        @answers[:two_j4][:value] = ((@answers[:two_i4][:value].to_f / @answers[:two_b4][:value]) * 100).round(2)
        @answers[:two_j5][:value] = ((@answers[:two_i5][:value].to_f / @answers[:two_b5][:value]) * 100).round(2)
        @answers[:two_j6][:value] = ((@answers[:two_i6][:value].to_f / @answers[:two_b6][:value]) * 100).round(2)
        @answers[:two_j7][:value] = ((@answers[:two_i7][:value].to_f / @answers[:two_b7][:value]) * 100).round(2)


        Rails.logger.info @answers.inspect
        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    def support_for answer:, data:
      case answer
      when :two_b2, :two_b3, :two_b4, :two_b5, :two_b6
        add_support(
          headers: ['Client ID', 'Personal IDs', 'Project', 'Project Type', 'Destination', 'Start Date', 'Exit Date'],
          data: data.map do |m|
            [
              m[:client_id],
              @client_personal_ids[m[:client_id]].join(', '),
              m[:project_name],
              HUD::project_type(m[:project_type]),
              HUD::destination(m[:destination]),
              m[:first_date_in_program],
              m[:last_date_in_program]
            ]
          end
        )
      when :two_c2, :two_c3, :two_c4, :two_c5, :two_c6, :two_e2, :two_e3, :two_e4, :two_e5, :two_e6, :two_g2, :two_g3, :two_g4, :two_g5, :two_g6
        add_support(
          headers: ['Client ID', 'Personal IDs', 'Days'],
          data: data.map do |(id, days)|
            [
              id,
              @client_personal_ids[id].join(', '),
              days,
            ]
          end
        )
      end
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

    def children_without_destination(project_types)
      # 99 = Not collected
      destination_not_collected = [99]

      @child_ids ||= {}
      @child_ids[project_types] ||= begin
        child_candidates_scope =  GrdaWarehouse::ServiceHistoryEnrollment.entry.
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
          pluck(
            :client_id,
            c_t[:DOB],
            e_t[:EntryDate],
            :age,
            :head_of_household_id,
            :household_id
          )

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
        two_a2: {
          title:  nil,
          value: 'Exit was from SO',
        },
        two_a3: {
          title: nil,
          value: 'Exit was from ES',
        },
        two_a4: {
          title: nil,
          value: 'Exit was from TH',
        },
        two_a5: {
          title: nil,
          value: 'Exit was from SH',
        },
        two_a6: {
          title: nil,
          value: 'Exit was from PH',
        },
        two_a7: {
          title: nil,
          value: 'Total retuns to homelessness',
        },
        two_b1: {
          title: nil,
          value: 'Total number of persons who exited to a permanent housing destination (2 Years Prior)',
        },
        two_b2: {
          title: 'Total number of persons who exited to a permanent housing destination; exit was from SO (2 years prior)',
          value: 0,
        },
        two_b3: {
          title: 'Total number of persons who exited to a permanent housing destination; exit was from ES (2 years prior)',
          value: 0,
        },
        two_b4: {
          title: 'Total number of persons who exited to a permanent housing destination; exit was from TH (2 years prior)',
          value: 0,
        },
        two_b5: {
          title: 'Total number of persons who exited to a permanent housing destination; exit was from SH (2 years prior)',
          value: 0,
        },
        two_b6: {
          title: 'Total number of persons who exited to a permanent housing destination; exit was from PH (2 years prior)',
          value: 0,
        },
        two_b7: {
          title: 'Total number of persons who exited to a permanent housing destination; Total retuns to homelessness (2 years prior)',
          value: 0,
        },
        two_c1: {
          title: nil,
          value: 'Number returing to homelessness in less than 6 months (0-180 days)',
        },
        two_c2: {
          title: 'Number returing to homelessness in less than 6 months; exit was from SO (0-180 days) ',
          value: 0,
        },
        two_c3: {
          title: 'Number returing to homelessness in less than 6 months; exit was from ES (0-180 days) ',
          value: 0,
        },
        two_c4: {
          title: 'Number returing to homelessness in less than 6 months; exit was from TH (0-180 days) ',
          value: 0,
        },
        two_c5: {
          title: 'Number returing to homelessness in less than 6 months; exit was from SH (0-180 days) ',
          value: 0,
        },
        two_c6: {
          title: 'Number returing to homelessness in less than 6 months; exit was from PH (0-180 days) ',
          value: 0,
        },
        two_c7: {
          title: 'Number returing to homelessness in less than 6 months; Total retuns to homelessness (0-180 days) ',
          value: 0,
        },
        two_d1: {
          title: nil,
          value: 'Percentage of returns in less than 6 months (0-180 days)',
        },
        two_d2: {
          title: 'Percentage of returns in less than 6 months; exit was from SO (0-180 days)',
          value: 0,
        },
        two_d3: {
          title: 'Percentage of returns in less than 6 months; exit was from ES (0-180 days)',
          value: 0,
        },
        two_d4: {
          title: 'Percentage of returns in less than 6 months; exit was from TH (0-180 days)',
          value: 0,
        },
        two_d5: {
          title: 'Percentage of returns in less than 6 months; exit was from SH (0-180 days)',
          value: 0,
        },
        two_d6: {
          title: 'Percentage of returns in less than 6 months; exit was from PH (0-180 days)',
          value: 0,
        },
        two_d7: {
          title: 'Percentage of returns in less than 6 months; Total retuns to homelessness (0-180 days)',
          value: 0,
        },
        two_e1: {
          title: nil,
          value: 'Number returning to homelessness from 6 to 12 months (181-365 days)',
        },
        two_e2: {
          title: 'Number returning to homelessness from 6 to 12 months; exit was from SO (181-365 days)',
          value: 0,
        },
        two_e3: {
          title: 'Number returning to homelessness from 6 to 12 months; exit was from ES (181-365 days)',
          value: 0,
        },
        two_e4: {
          title: 'Number returning to homelessness from 6 to 12 months; exit was from TH (181-365 days)',
          value: 0,
        },
        two_e5: {
          title: 'Number returning to homelessness from 6 to 12 months; exit was from SH (181-365 days)',
          value: 0,
        },
        two_e6: {
          title: 'Number returning to homelessness from 6 to 12 months; exit was from PH (181-365 days)',
          value: 0,
        },
        two_e7: {
          title: 'Number returning to homelessness from 6 to 12 months; Total retuns to homelessness (181-365 days)',
          value: 0,
        },
        two_f1: {
          title: nil,
          value: 'Percentage of returns from 6 to 12 months (181-365 days)',
        },
        two_f2: {
          title: 'Percentage of returns from 6 to 12 months; exit was from SO (181-365 days)',
          value: 0,
        },
        two_f3: {
          title: 'Percentage of returns from 6 to 12 months; exit was from ES (181-365 days)',
          value: 0,
        },
        two_f4: {
          title: 'Percentage of returns from 6 to 12 months; exit was from TH (181-365 days)',
          value: 0,
        },
        two_f5: {
          title: 'Percentage of returns from 6 to 12 months; exit was from SH (181-365 days)',
          value: 0,
        },
        two_f6: {
          title: 'Percentage of returns from 6 to 12 months; exit was from PH (181-365 days)',
          value: 0,
        },
        two_f7: {
          title: 'Percentage of returns from 6 to 12 months; Total retuns to homelessness (181-365 days)',
          value: 0,
        },
        two_g1: {
          title: nil,
          value: 'Number returning to homelessness from 13 to 24 months (366-730 days)',
        },
        two_g2: {
          title: 'Number returning to homelessness from 13 to 24 months; exit was from SO (366-730 days)',
          value: 0,
        },
        two_g3: {
          title: 'Number returning to homelessness from 13 to 24 months; exit was from ES (366-730 days)',
          value: 0,
        },
        two_g4: {
          title: 'Number returning to homelessness from 13 to 24 months; exit was from TH (366-730 days)',
          value: 0,
        },
        two_g5: {
          title: 'Number returning to homelessness from 13 to 24 months; exit was from SH (366-730 days)',
          value: 0,
        },
        two_g6: {
          title: 'Number returning to homelessness from 13 to 24 months; exit was from PH (366-730 days)',
          value: 0,
        },
        two_g7: {
          title: 'Number returning to homelessness from 13 to 24 months; Total retuns to homelessness (366-730 days)',
          value: 0,
        },
        two_h1: {
          title: nil,
          value: 'Percentage of returns from 13 to 24 months (366-730 days)',
        },
        two_h2: {
          title: 'Percentage of returns from 13 to 24 months; exit was from SO (366-730 days)',
          value: 0,
        },
        two_h3: {
          title: 'Percentage of returns from 13 to 24 months; exit was from ES (366-730 days)',
          value: 0,
        },
        two_h4: {
          title: 'Percentage of returns from 13 to 24 months; exit was from TH (366-730 days)',
          value: 0,
        },
        two_h5: {
          title: 'Percentage of returns from 13 to 24 months; exit was from SH (366-730 days)',
          value: 0,
        },
        two_h6: {
          title: 'Percentage of returns from 13 to 24 months; exit was from PH (366-730 days)',
          value: 0,
        },
        two_h7: {
          title: 'Percentage of returns from 13 to 24 months; Total retuns to homelessness (366-730 days)',
          value: 0,
        },
        two_i1: {
          title: nil,
          value: 'Number of returns in 2 years',
        },
        two_i2: {
          title: 'Number of returns in 2 years; exit was from SO',
          value: 0,
        },
        two_i3: {
          title: 'Number of returns in 2 years; exit was from ES',
          value: 0,
        },
        two_i4: {
          title: 'Number of returns in 2 years; exit was from TH',
          value: 0,
        },
        two_i5: {
          title: 'Number of returns in 2 years; exit was from SH',
          value: 0,
        },
        two_i6: {
          title: 'Number of returns in 2 years; exit was from PH',
          value: 0,
        },
        two_i7: {
          title: 'Number of returns in 2 years; Total retuns to homelessness',
          value: 0,
        },
        two_j1: {
          title: nil,
          value: 'Percentage of returns in 2 years',
        },
        two_j2: {
          title: 'Percentage of returns in 2 years; exit was from SO',
          value: 0,
        },
        two_j3: {
          title: 'Percentage of returns in 2 years; exit was from ES',
          value: 0,
        },
        two_j4: {
          title: 'Percentage of returns in 2 years; exit was from TH',
          value: 0,
        },
        two_j5: {
          title: 'Percentage of returns in 2 years; exit was from SH',
          value: 0,
        },
        two_j6: {
          title: 'Percentage of returns in 2 years; exit was from PH',
          value: 0,
        },
        two_j7: {
          title: 'Percentage of returns in 2 years; Total retuns to homelessness',
          value: 0,
        },
      }
    end
  end
end
