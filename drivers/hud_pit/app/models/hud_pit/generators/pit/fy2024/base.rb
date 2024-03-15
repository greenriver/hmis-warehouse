###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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

module HudPit::Generators::Pit::Fy2024
  class Base < ::HudReports::QuestionBase
    include ArelHelper
    include HudReports::Util
    include HudReports::Clients
    include HudReports::Ages
    include HudReports::Households
    include HudReports::Veterans

    PROJECT_TYPES = {
      th: 2,
      es: [0, 1],
      sh: 8,
      so: 4,
    }.freeze

    def self.allowed_options
      HudPit::Generators::Pit::Fy2024::Generator.allowed_options
    end

    private def universe
      add unless populated?

      @universe ||= @report.universe(self.class.question_number)
    end

    private def add
      @generator.client_scope.find_in_batches(batch_size: batch_size) do |batch|
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

          dv_record = enrollment.health_and_dvs.
            select { |h| h.InformationDate <= @generator.filter.on && !h.DomesticViolenceVictim.nil? }.
            max_by(&:InformationDate)

          if processed_source_clients.include?(source_client.id)
            @notifier.ping "Duplicate source client: #{source_client.id} for destination client: #{client.id} in enrollment: #{enrollment.id}" if @send_notifications
            next
          end

          age = source_client.age_on(@generator.filter.on)
          hh_id = get_hh_id(last_service_history_enrollment)
          hoh_enrollment = enrollments_by_client_id[get_hoh_id(hh_id)]&.last&.enrollment
          household_ages = ages_for(hh_id, @generator.filter.on)
          household_type = household_types[hh_id]
          # https://files.hudexchange.info/resources/documents/Reporting-Gender-for-the-PIT-Count.pdf
          more_than_one_gender = HudPit::Fy2024::PitClient.more_than_one_gender(source_client)
          pit_gender = source_client.pit_gender
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
            household_member_count: household_ages.count,
            hoh_age: hoh_age(hh_id, @generator.filter.on),
            hoh_veteran: hoh_veteran,
            head_of_household: enrollment.RelationshipToHoH == 1,
            relationship_to_hoh: enrollment.RelationshipToHoH,
            more_than_one_gender: more_than_one_gender,
            female: source_client.Woman,
            male: source_client.Man,
            culturally_specific: source_client.CulturallySpecific,
            different_identity: source_client.DifferentIdentity,
            non_binary: source_client.NonBinary,
            transgender: source_client.Transgender,
            questioning: source_client.Questioning,
            gender_none: source_client.GenderNone,
            pit_race: pit_race,
            pit_gender: pit_gender,
            am_ind_ak_native: source_client.AmIndAKNative,
            asian: source_client.Asian,
            black_af_american: source_client.BlackAfAmerican,
            native_hi_other_pacific: source_client.NativeHIPacific,
            white: source_client.White,
            mid_east_n_african: source_client.MidEastNAfrican,
            race_none: source_client.RaceNone,
            veteran: source_client.VeteranStatus,
            chronically_homeless: enrollment.chronically_homeless_at_start?(date: @generator.filter.on),
            chronically_homeless_household: hoh_enrollment&.chronically_homeless_at_start?(date: @generator.filter.on),
            substance_use: disabilities_latest.detect(&:substance?)&.DisabilityResponse&.present?,
            substance_use_indefinite_impairing: disabilities_latest.detect { |d| d.indefinite_and_impairs? && d.substance? }&.DisabilityResponse.present?,
            domestic_violence: dv_record&.DomesticViolenceVictim,
            domestic_violence_currently_fleeing: dv_record&.CurrentlyFleeing,
            hiv_aids: disabilities_latest.detect(&:hiv?)&.DisabilityResponse&.present?,
            mental_illness: disabilities_latest.detect(&:mental?)&.DisabilityResponse&.present?,
            mental_illness_indefinite_impairing: disabilities_latest.detect { |d| d.indefinite_and_impairs? && d.mental? }&.DisabilityResponse.present?,
            project_type: last_service_history_enrollment.project_type,
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
      # ES > SH > TH > SO ([0, 1], 8, 2, 4)
      # if there isn't one of these, move on
      # reverse so we get the most-recent enrollment
      last_service_history_enrollment ||= enrollments.reverse_each.detect { |en| en.computed_project_type.in?(PROJECT_TYPES[:es]) }
      last_service_history_enrollment ||= enrollments.reverse_each.detect { |en| en.computed_project_type == PROJECT_TYPES[:sh] }
      last_service_history_enrollment ||= enrollments.reverse_each.detect { |en| en.computed_project_type == PROJECT_TYPES[:th] }
      last_service_history_enrollment ||= enrollments.reverse_each.detect { |en| en.computed_project_type == PROJECT_TYPES[:so] }
      last_service_history_enrollment
    end

    private def report_client_universe
      HudPit::Fy2024::PitClient
    end

    private def clients_with_enrollments(batch, scope: enrollment_scope, **)
      scope.
        where(client_id: batch.map(&:id)).
        order(first_date_in_program: :asc).
        group_by(&:client_id)
    end

    private def enrollment_scope
      preloads = [
        :client,
        {
          enrollment: [
            :disabilities,
            :project,
            :enrollment_coc_at_entry,
            :health_and_dvs,
            :exit,
          ],
        },
      ]
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
        age_25_34: {
          title: 'Number of Persons (25 - 34)',
          query: age_ranges['25-34'],
        },
        age_35_44: {
          title: 'Number of Persons (35 - 44)',
          query: age_ranges['35-44'],
        },
        age_45_54: {
          title: 'Number of Persons (45 - 54)',
          query: age_ranges['45-54'],
        },
        age_55_64: {
          title: 'Number of Persons (55 - 64)',
          query: age_ranges['55-64'],
        },
        age_over_64: {
          title: 'Number of Persons (over age 64)',
          query: age_ranges['65+'],
        },
        youth_hoh: {
          title: 'Number of parenting youth (age 18 to 24)',
          query: hoh_clause.and(age_ranges['18-24']),
        },
        child_hoh: {
          title: 'Number of parenting youth (under age 18)',
          query: hoh_clause.and(child_clause),
        },
        hoh_for_youth: { # note because the question is already limited to youth households, this is just here to provide the title
          title: 'Number of parenting youth (youth parents only)',
          query: hoh_clause,
        },
        children_of_youth_parents: {
          title: 'Total Children in Parenting Youth Households',
          query: a_t[:head_of_household].eq(false).and(child_clause),
        },
        children_of_18_to_24_parents: {
          title: 'Children in households with parenting youth age 18 to 24 (children under age 18 with parents age 18 to 24)',
          query: a_t[:head_of_household].eq(false).and(child_clause).and(a_t[:hoh_age].in(18..24)),
        },
        children_of_0_to_18_parents: {
          title: 'Children in households with parenting youth under age 18 (children under age 18 with parents under 18)',
          query: a_t[:head_of_household].eq(false).and(child_clause).and(a_t[:hoh_age].in(0..17)),
        },
        woman: {
          title: 'Woman (Girl, if child)',
          query: a_t[:pit_gender].eq('Woman (Girl, if child)'),
        },
        man: {
          title: 'Man (Boy, if child)',
          query: a_t[:pit_gender].eq('Man (Boy, if child)'),
        },
        culturally_specific_identity: {
          title: 'Culturally Specific Identity (e.g., Two-Spirit)',
          query: a_t[:pit_gender].eq('Culturally Specific Identity (e.g., Two-Spirit)'),
        },
        transgender: {
          title: 'Transgender',
          query: a_t[:pit_gender].eq('Transgender'),
        },
        non_binary: {
          title: 'Non-Binary',
          query: a_t[:pit_gender].eq('Non-Binary'),
        },
        questioning: {
          title: 'Questioning',
          query: a_t[:pit_gender].eq('Questioning'),
        },
        different_identity: {
          title: 'Different Identity',
          query: a_t[:pit_gender].eq('Different Identity'),
        },
        more_than_one_gender: {
          title: 'More Than One Gender',
          query: a_t[:pit_gender].eq('More Than One Gender'),
        },
        native_ak: {
          title: 'American Indian, Alaska Native, or Indigenous (only)',
          query: a_t[:pit_race].eq('American Indian, Alaska Native, or Indigenous (only)'),
        },
        native_ak_latino: {
          title: 'American Indian, Alaska Native, or Indigenous & Hispanic/Latina/e/o',
          query: a_t[:pit_race].eq('American Indian, Alaska Native, or Indigenous & Hispanic/Latina/e/o'),
        },
        asian: {
          title: 'Asian or Asian American (only)',
          query: a_t[:pit_race].eq('Asian or Asian American (only)'),
        },
        asian_latino: {
          title: 'Asian or Asian American & Hispanic/Latina/e/o',
          query: a_t[:pit_race].eq('Asian or Asian American & Hispanic/Latina/e/o'),
        },
        black_af_american: {
          title: 'Black, African American, or African (only)',
          query: a_t[:pit_race].eq('Black, African American, or African (only)'),
        },
        black_af_american_latino: {
          title: 'Black, African American, or African & Hispanic/Latina/e/o',
          query: a_t[:pit_race].eq('Black, African American, or African & Hispanic/Latina/e/o'),
        },
        latino_only: {
          title: 'Hispanic/Latina/e/o (only)',
          query: a_t[:pit_race].eq('Hispanic/Latina/e/o (only)'),
        },
        mid_east_na: {
          title: 'Middle Eastern or North African (only)',
          query: a_t[:pit_race].eq('Middle Eastern or North African (only)'),
        },
        mid_east_na_latino: {
          title: 'Middle Eastern or North African & Hispanic/Latina/e/o',
          query: a_t[:pit_race].eq('Middle Eastern or North African & Hispanic/Latina/e/o'),
        },
        native_pi: {
          title: 'Native Hawaiian or Pacific Islander (only)',
          query: a_t[:pit_race].eq('Native Hawaiian or Pacific Islander (only)'),
        },
        native_pi_latino: {
          title: 'Native Hawaiian or Pacific Islander & Hispanic/Latina/e/o',
          query: a_t[:pit_race].eq('Native Hawaiian or Pacific Islander & Hispanic/Latina/e/o'),
        },
        white: {
          title: 'White (only)',
          query: a_t[:pit_race].eq('White (only)'),
        },
        white_latino: {
          title: 'White & Hispanic/Latina/e/o',
          query: a_t[:pit_race].eq('White & Hispanic/Latina/e/o'),
        },
        multi_racial: {
          title: 'Multi-Racial (all other)',
          query: a_t[:pit_race].eq('Multi-Racial (all other)'),
        },
        multi_racial_latino: {
          title: 'Multi-Racial & Hispanic/Latina/e/o',
          query: a_t[:pit_race].eq('Multi-Racial & Hispanic/Latina/e/o'),
        },
        chronic_households: {
          title: 'Chronically Homeless: Total number of households',
          query: a_t[:chronically_homeless].eq(true).and(hoh_clause),
        },
        chronic_clients: {
          title: 'Chronically Homeless: Total number of persons',
          query: a_t[:chronically_homeless_household].eq(true),
        },
        adults_with_mental_illness: {
          title: 'Adults with a Serious Mental Illness',
          query: a_t[:mental_illness].eq(true),
        },
        adults_with_substance_use: {
          title: 'Adults with a Substance Use Disorder',
          query: a_t[:substance_use].eq(true),
        },
        adults_with_hiv: {
          title: 'Adults with HIV/AIDS',
          query: a_t[:hiv_aids].eq(true),
        },
        adult_dv_survivors: {
          title: 'Adult Survivors of Domestic Violence (optional)',
          query: a_t[:domestic_violence].eq(true),
        },
      }
    end

    private def row_labels
      rows.map do |key|
        sub_calculations[key][:title]
      end
    end

    private def row_limits
      {}
    end

    def label_for(key)
      field_labels.fetch(key)
    end

    def field_labels
      {
        dkptr: 'Client Doesn’t Know/Prefers Not to Answer',
        info_missing: 'Information Missing',
        data_not_collected: 'Data Not Collected',
      }
    end

    private def populate_table(table_name, metadata)
      @report.answer(question: table_name).update(metadata: metadata)
      project_types.each.with_index do |project_clause, column_num|
        rows.each.with_index do |key, row_num|
          row = row_num + 2
          cell = "#{(column_num + 2).to_csv_column}#{row}"
          calc = sub_calculations[key]
          members = universe.members.where(project_clause).where(calc[:query])
          members = members.where(row_limits[row]) if row_limits.key?(row)
          answer = @report.answer(question: table_name, cell: cell)
          answer.add_members(members)
          # puts "Added: #{members.count} to: #{cell} for: #{calc[:title]} #{universe.members.where(project_clause).where(calc[:query]).to_sql}\n\n"
          answer.update(summary: members.count)
        end
      end
    end

    private def a_t
      @a_t ||= HudPit::Fy2024::PitClient.arel_table
    end

    private def project_type_es_clause
      a_t[:project_type].in([0, 1])
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
