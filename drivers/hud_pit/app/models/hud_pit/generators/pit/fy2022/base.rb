###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# PIT Notes
#   CoCs should report on people based on where they are sleeping on the night of the count, as opposed to the program they are enrolled in.
#    RRH + PH (don't count)
#    RRH + ES/SO/TH/SH - do count
#
# Count includes sheltered and unsheltered count
#   Count sheltered individuals who entered on or before the count date who exited after the count date (or not at all)
#   Unsheltered may be counted on the day of or day after the count
#
# Youth breakdown - no one > 24
# Parenting youth - subset of households with children if parent >= 18 <= 24 with children,
#   or subset of children only if parent < 18
# Unaccompanied youth - individual < 25 counted as a subset of households with only children if < 18, households without children if >= 18 <= 24

module HudPit::Generators::Pit::Fy2022
  class Base < ::HudReports::QuestionBase
    include ArelHelper
    include HudReports::Util
    include HudReports::Clients
    include HudReports::Ages
    include HudReports::Households
    include HudReports::Veterans

    PROJECT_TYPES = {
      th: 2,
      es: 1,
      sh: 8,
      so: 4,
    }.freeze

    private def universe
      add unless populated?

      @universe ||= @report.universe(self.class.question_number)
    end

    private def add
      @generator.client_scope.find_in_batches(batch_size: 1_000) do |batch|
        enrollments_by_client_id = clients_with_enrollments(batch)
        services_by_client_id = services_on_pit_date(batch)

        # Pre-calculate some values
        household_types = {}
        enrollments_by_client_id.each do |_, enrollments|
          last_service_history_enrollment = enrollment_from(enrollments)
          next unless last_service_history_enrollment

          hh_id = get_hh_id(last_service_history_enrollment)
          household_types[hh_id] = household_makeup(hh_id, @generator.filter.on)
        end

        pending_associations = {}
        processed_source_clients = Set.new
        # Re-shape client to PIT Client shape
        batch.each do |client|
          # Fetch enrollments for destination client
          enrollments = enrollments_by_client_id[client.id]
          services = services_by_client_id[client.id]
          next if enrollments.blank?
          # If the client has a PH with move-in, drop them
          next if services.any? { |s| s.homeless == false }

          last_service_history_enrollment = enrollment_from(enrollments)
          enrollment = last_service_history_enrollment&.enrollment
          next unless enrollment

          source_client = enrollment.client
          next unless source_client

          disabilities = enrollment.disabilities.select { |disability| [1, 2, 3].include?(disability.DisabilityResponse) }
          max_disability_date = disabilities.select { |d| d.InformationDate <= @generator.filter.on }.
            map(&:InformationDate).max
          disabilities_latest = disabilities.select { |d| d.InformationDate == max_disability_date }

          health_and_dv = enrollment.health_and_dvs.
            select { |h| h.InformationDate <= @generator.filter.on && !h.DomesticViolenceVictim.nil? }.
            max_by(&:InformationDate)

          if processed_source_clients.include?(source_client.id)
            @notifier.ping "Duplicate source client: #{source_client.id} for destination client: #{client.id} in enrollment: #{enrollment.id}" if @send_notifications
            next
          end

          age = source_client.age_on(@generator.filter.on)
          hh_id = get_hh_id(last_service_history_enrollment)
          household_ages = ages_for(hh_id, @generator.filter.on)
          household_type = household_types[hh_id]
          # https://files.hudexchange.info/resources/documents/Reporting-Gender-for-the-PIT-Count.pdf
          binary_gender_code = source_client.gender_binary
          binary_gender_code = 4 if binary_gender_code == 6
          pit_gender = HUD.gender(binary_gender_code)
          # Only count clients once (where one category is Multiple Races)
          pit_race = source_client.pit_race
          processed_source_clients << source_client.id
          # NOTE: member is a hash with string keys
          hoh_veteran = household_member_data(last_service_history_enrollment).detect do |member|
            next unless member

            member['veteran_status'] == 1 && member['relationship_to_hoh'] == 1
          end.present?

          options = {
            client_id: source_client.id,
            destination_client_id: last_service_history_enrollment.client_id,
            data_source_id: source_client.data_source_id,
            report_instance_id: @report.id,

            age: age,
            dob: source_client.DOB,
            first_name: source_client.FirstName,
            last_name: source_client.LastName,
            household_type: household_type,
            max_age: household_ages.compact&.max,
            hoh_veteran: hoh_veteran,
            head_of_household: enrollment.RelationshipToHoH == 1,
            relationship_to_hoh: enrollment.RelationshipToHoH,
            pit_gender: pit_gender,
            female: source_client.Female,
            male: source_client.Male,
            no_single_gender: source_client.NoSingleGender,
            transgender: source_client.Transgender,
            questioning: source_client.Questioning,
            gender_none: source_client.GenderNone,
            pit_race: pit_race,
            am_ind_ak_native: source_client.AmIndAKNative,
            asian: source_client.Asian,
            black_af_american: source_client.BlackAfAmerican,
            native_hi_other_pacific: source_client.NativeHIPacific,
            white: source_client.White,
            race_none: source_client.RaceNone,
            ethnicity: source_client.Ethnicity,
            veteran: source_client.VeteranStatus,
            chronically_homeless: enrollment.chronically_homeless_at_start?(@generator.filter.on),
            substance_use: disabilities_latest.detect(&:substance?)&.DisabilityResponse&.present?,
            substance_use_indefinite_impairing: disabilities_latest.detect { |d| d.indefinite_and_impairs? && d.substance? }&.DisabilityResponse.present?,
            domestic_violence: health_and_dv&.DomesticViolenceVictim,
            domestic_violence_currently_fleeing: health_and_dv&.CurrentlyFleeing,
            hiv_aids: disabilities_latest.detect(&:hiv?)&.DisabilityResponse&.present?,
            hiv_aids_indefinite_impairing: disabilities_latest.detect { |d| d.indefinite_and_impairs? && d.hiv? }&.DisabilityResponse.present?,
            mental_illness: disabilities_latest.detect(&:mental?)&.DisabilityResponse&.present?,
            mental_illness_indefinite_impairing: disabilities_latest.detect { |d| d.indefinite_and_impairs? && d.mental? }&.DisabilityResponse.present?,
            project_type: last_service_history_enrollment.computed_project_type,
            project_name: last_service_history_enrollment.project_name,
            project_id: last_service_history_enrollment.project.id,
            project_hmis_pit_count: last_service_history_enrollment.project.PITCount,
            entry_date: last_service_history_enrollment.first_date_in_program,
            exit_date: last_service_history_enrollment.last_date_in_program,
          }
          pending_associations[client] = report_client_universe.new(options)
        end

        # Import PIT clients
        report_client_universe.import(
          pending_associations.values,
          on_duplicate_key_update: {
            conflict_target: [:client_id, :data_source_id, :report_instance_id],
            columns: pending_associations.values.first&.changes&.keys || [],
          },
        )

        # Attach PIT Clients to relevant questions
        @report.build_for_questions.each do |question_number|
          universe_cell = @report.universe(question_number)
          generator = @generator.class.questions[question_number]
          universe_cell.add_universe_members(generator.filter_pending_associations(pending_associations))
        end
      end
    end

    private def enrollment_from(enrollments)
      # Instead of the usual choosing the last enrollment, choose the one in this order:
      # ES > SH > TH > SO (1, 8, 2, 4)
      # if there isn't one of these, move on
      # reverse so we get the most-recent enrollment
      last_service_history_enrollment ||= enrollments.reverse_each.detect { |en| en.computed_project_type == PROJECT_TYPES[:es] }
      last_service_history_enrollment ||= enrollments.reverse_each.detect { |en| en.computed_project_type == PROJECT_TYPES[:sh] }
      last_service_history_enrollment ||= enrollments.reverse_each.detect { |en| en.computed_project_type == PROJECT_TYPES[:th] }
      last_service_history_enrollment ||= enrollments.reverse_each.detect { |en| en.computed_project_type == PROJECT_TYPES[:so] }
      last_service_history_enrollment
    end

    private def report_client_universe
      HudPit::Fy2022::PitClient
    end

    private def clients_with_enrollments(batch)
      enrollment_scope.
        where(client_id: batch.map(&:id)).
        order(first_date_in_program: :asc).
        group_by(&:client_id)
    end

    private def enrollment_scope
      preloads = {
        enrollment: [
          :disabilities,
          :project,
          :enrollment_coc_at_entry,
          :health_and_dvs,
          :exit,
        ],
      }
      enrollment_scope_without_preloads.preload(preloads)
    end

    # open enrollments on the date with service that isn't extrapolated
    private def enrollment_scope_without_preloads
      scope = GrdaWarehouse::ServiceHistoryEnrollment.
        entry.
        residential.
        ongoing(on_date: @generator.filter.on).
        with_service_between(start_date: @generator.filter.on, end_date: @generator.filter.on, service_scope: :service_excluding_extrapolated).
        joins(:enrollment)
      scope = scope.in_project(@report.project_ids) if @report.project_ids.present? # for consistency with client_scope
      scope
    end

    delegate :client_scope, to: :@generator

    private def populated?
      @report.report_cells.joins(universe_members: :client).exists?
    end

    def services_on_pit_date(batch)
      GrdaWarehouse::ServiceHistoryService.service_excluding_extrapolated.
        where(date: @generator.filter.on).
        joins(:service_history_enrollment).
        merge(enrollment_scope_without_preloads.where(client_id: batch.map(&:id))).
        group_by(&:client_id)
    end

    private def sub_calculations
      {
        households: {
          title: 'Total Number of Households',
          query: hoh_clause,
        },
        clients: {
          title: 'Total Number of Persons',
          query: Arel.sql('1=1'),
        },
        veterans: {
          title: 'Total Number of Veterans',
          query: a_t[:veteran].eq(1),
        },
        children: {
          title: 'Number of Persons (under age 18)',
          query: child_clause,
        },
        youth: {
          title: 'Number of Persons (18 - 24)',
          query: age_ranges['18-24'],
        },
        youth_hoh: {
          title: 'Number of parenting youth (youth parents only)',
          query: hoh_clause.and(age_ranges['18-24']),
        },
        child_hoh: {
          title: 'Number of parenting youth (under age 18)',
          query: hoh_clause.and(child_clause),
        },
        hoh_for_youth: { # note because the question is already limted to youth households, this is just here to provide the title
          title: 'Number of parenting youth (youth parents only)',
          query: hoh_clause,
        },
        children_of_youth_parents: {
          title: 'Number of children with parenting youth (children under age 18 with parents under age 25)',
          query: a_t[:head_of_household].eq(false).and(child_clause),
        },
        over_24: {
          title: 'Number of Persons (over age 24)',
          query: a_t[:age].gteq(25),
        },
        female: {
          title: 'Female',
          query: a_t[:pit_gender].eq('Female'),
        },
        male: {
          title: 'Male',
          query: a_t[:pit_gender].eq('Male'),
        },
        transgender: {
          title: 'Transgender',
          query: a_t[:pit_gender].eq('Transgender'),
        },
        gender_other: {
          title: 'Gender Don’t identify as male, female, or transgender',
          query: a_t[:pit_gender].eq('A gender other than singularly female or male (e.g., non-binary, genderfluid, agender, culturally specific gender)'),
        },
        non_latino: {
          title: 'Non-Hispanic/Non-Latino',
          query: a_t[:ethnicity].not_eq(1),
        },
        latino: {
          title: 'Hispanic/Latino',
          query: a_t[:ethnicity].eq(1),
        },
        white: {
          title: 'White',
          query: a_t[:pit_race].eq('White'),
        },
        black: {
          title: 'Black or African-American',
          query: a_t[:pit_race].eq('BlackAfAmerican'),
        },
        asian: {
          title: 'Asian',
          query: a_t[:pit_race].eq('Asian'),
        },
        native_ak: {
          title: 'American Indian or Alaska Native',
          query: a_t[:pit_race].eq('AmIndAKNative'),
        },
        native_pi: {
          title: 'Native Hawaiian or Other Pacific Islander',
          query: a_t[:pit_race].eq('NativeHIPacific'),
        },
        multi_racial: {
          title: 'Multiple Races',
          query: a_t[:pit_race].eq('MultiRacial'),
        },
        chronic_households: {
          title: 'Chronically Homeless: Total number of households',
          query: a_t[:chronically_homeless].eq(true).and(hoh_clause),
        },
        chronic_clients: {
          title: 'Chronically Homeless: Total number of persons',
          query: a_t[:chronically_homeless].eq(true),
        },
        adults_with_mental_illness: {
          title: 'Adults with a Serious Mental Illness',
          query: a_t[:mental_illness].eq(true),
        },
        adults_with_mental_illness_indefinite: {
          title: 'Adults with indefinite and impairing Serious Mental Illness',
          query: a_t[:mental_illness_indefinite_impairing].eq(true),
        },
        adults_with_substance_use: {
          title: 'Adults with a Substance Use Disorder',
          query: a_t[:substance_use].eq(true),
        },
        adults_with_substance_use_indefinite: {
          title: 'Adults with indefinite and impairing Substance Use Disorder',
          query: a_t[:substance_use_indefinite_impairing].eq(true),
        },
        adults_with_hiv: {
          title: 'Adults with HIV/AIDS',
          query: a_t[:hiv_aids].eq(true),
        },
        adults_with_hiv_indefinite: {
          title: 'Adults with indefinite and impairing HIV/AIDS',
          query: a_t[:hiv_aids_indefinite_impairing].eq(true),
        },
        adult_dv_survivors: {
          title: 'Adult Survivors of Domestic Violence (optional)',
          query: a_t[:domestic_violence].eq(true),
        },
        adult_dv_survivors_currently_fleeing: {
          title: 'Adult Survivors of Domestic Violence (optional) Currently Fleeing',
          query: a_t[:domestic_violence_currently_fleeing].eq(true),
        },
      }
    end

    private def row_labels
      rows.map do |key|
        sub_calculations[key][:title]
      end
    end

    private def populate_table(table_name, metadata)
      @report.answer(question: table_name).update(metadata: metadata)
      project_types.each.with_index do |project_clause, column_num|
        rows.each.with_index do |key, row_num|
          cell = "#{(column_num + 2).to_csv_column}#{row_num + 2}"
          calc = sub_calculations[key]
          members = universe.members.where(project_clause).where(calc[:query])
          answer = @report.answer(question: table_name, cell: cell)
          answer.add_members(members)
          # puts "Added: #{members.count} to: #{cell} for: #{calc[:title]} #{universe.members.where(project_clause).where(calc[:query]).to_sql}\n\n"
          answer.update(summary: members.count)
        end
      end
    end

    private def a_t
      @a_t ||= HudPit::Fy2022::PitClient.arel_table
    end

    private def project_type_es_clause
      a_t[:project_type].eq(1)
    end

    private def project_type_th_clause
      a_t[:project_type].eq(2)
    end

    private def project_type_so_clause
      a_t[:project_type].eq(4)
    end

    private def project_type_sh_clause
      a_t[:project_type].eq(8)
    end
  end
end
