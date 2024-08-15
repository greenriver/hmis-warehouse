###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2024
  class QuestionTwentySeven < Base
    include HudReports::SubPopulationsBySubsidyTypeQuestion
    include HudReports::SubPopulationsByDestinationQuestion
    include HudReports::StartToMoveInQuestion
    include HudReports::LivingSituationsQuestion
    include HudReports::GenderQuestion

    QUESTION_NUMBER = 'Question 27'.freeze

    def self.table_descriptions
      {
        'Question 27' => 'Youth Questions',
        'Q27a' => 'Age of Youth',
        'Q27b' => 'Parenting Youth',
        'Q27c' => 'Gender - Youth',
        'Q27d' => 'Living Situation - Youth',
        'Q27e' => 'Length of Participation - Youth',
        'Q27f1' => 'Exit Destination - Youth',
        'Q27f2' => 'Exit Destination - – Subsidy Type of Persons Exiting to Rental by Client With An Ongoing Subsidy',
        'Q27g' => 'Cash Income - Sources - Youth',
        'Q27h' => 'Client Cash Income Category - Earned/Other Income Category - by Start and Annual Assessment/Exit Status - Youth',
        'Q27i' => 'Disabling Conditions and Income for Youth at Exit',
        'Q27j' => 'Average and Median Length of Participation in Days - Youth',
        'Q27k' => 'Length of Time between Project Start Date and Housing Move-in Date - Youth',
        'Q27l' => 'Length of Time Prior to Housing - based on 3.917 Date Homelessness Started - Youth',
        'Q27m' => 'Education Status - Youth',
      }.freeze
    end

    private def youth_filter
      a_t[:age].between(12..24).and(a_t[:other_clients_over_25].eq(false)).
        and(a_t[:dob_quality].in([1, 2]))
    end

    private def q27a_youth_age
      table_name = 'Q27a'
      metadata = {
        header_row: [' '] + q27_populations.keys,
        row_labels: youth_age_ranges.keys,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 6,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      youth = universe.members.where(youth_filter)

      q27_populations.values.each_with_index do |population_clause, col_index|
        youth_age_ranges.values.each_with_index do |response_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank_27a.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = youth.
            where(population_clause).
            where(response_clause)
          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q27b_parenting_youth
      table_name = 'Q27b'
      metadata = {
        header_row: [' '] + q27b_populations.keys,
        row_labels: ['Parent youth < 18', 'Parent youth 18 to 24'],
        first_column: 'B',
        last_column: 'E',
        first_row: 2,
        last_row: 3,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q27b_populations.values.each_with_index do |population_clause, col_index|
        households = Set.new
        youth_parent_age_ranges.values.each_with_index do |response_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)
          # Scope initially to anyone in a family with a youth head of household of the appropriate age
          members = universe.members.where(
            a_t[:household_id].in(
              Arel.sql(
                universe.members.where(response_clause).select(a_t[:household_id]).to_sql,
              ),
            ),
          )

          source_client_ids = Set.new
          members.preload(:universe_membership).find_each do |member|
            apr_client = member.universe_membership
            case population_clause
            when :parenting_youth
              # We haven't already counted this household, the client is an HoH and all members are youth
              # report HoH and adults (18-24)
              if ! households.include?(apr_client.household_id) && apr_client.parenting_youth
                # since apr_client is the HoH and we've already limited to only youth households,
                # we can safely return the adults and the source client id of the apr_client
                adult_ids = adult_source_client_ids(apr_client)
                adult_ids << apr_client.client_id
                source_client_ids += adult_ids
                households << apr_client.household_id
              end
            when :children_of_youth_parents
              # Find source client ids where the HoH is a youth and the members are RelationshipToHoH == 2
              if ! households.include?(apr_client.household_id) && apr_client.parenting_youth
                source_client_ids += youth_child_source_client_ids(apr_client)
                households << apr_client.household_id
              end
            when :members_youth_households
              # Return all clients within the household, regardless of relationship
              if ! households.include?(apr_client.household_id) && apr_client.parenting_youth
                source_client_ids += apr_client.household_members.map { |m| m['source_client_id'] }
                households << apr_client.household_id
              end
            when :youth_households
              # Use the HoH as a proxy for household
              if ! households.include?(apr_client.household_id) && apr_client.parenting_youth
                source_client_ids << apr_client.client_id
                households << apr_client.household_id
              end
            end
          end
          members = if source_client_ids.any?
            members.where(a_t[:client_id].in(source_client_ids))
          else
            members.none
          end

          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q27c_youth_gender
      gender_question(
        question: 'Q27c',
        members: universe.members.where(youth_filter),
        populations: sub_populations,
      )
    end

    private def q27d_youth_living_situation
      living_situations_question(
        question: 'Q27d',
        members: universe.members.where(hoh_clause.and(a_t[:age].in(12..24)).and(a_t[:other_clients_over_25].eq(false))),
      )
    end

    private def q27e_youth_length_of_participation
      table_name = 'Q27e'
      metadata = {
        header_row: [' '] + q27e_populations.keys,
        row_labels: q27e_lengths.keys,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 12,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q27e_populations.values.each_with_index do |population_clause, col_index|
        q27e_lengths.values.each_with_index do |length_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(youth_filter).
            where(population_clause).
            where(length_clause)

          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    def q27f1_youth_destination
      sub_populations_by_destination_question(
        question: 'Q27f1',
        # FIXME: need to check this universe
        members: universe.members.where(youth_filter), # .where(youth_adult_or_youth_hoh_clause),
      )
    end

    def q27f2_subsidy_type_of_persons_exiting_to_rental_by_client_with_an_ongoing_subsidy
      sub_populations_by_subsidy_type_question(question: 'Q27f2', members: universe.members.where(youth_filter))
    end

    private def q27g_youth_income_sources
      table_name = 'Q27g'
      metadata = {
        header_row: [' '] + income_stages.keys,
        row_labels: income_headers_27g,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 17,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      income_stages.values.each_with_index do |suffix, col_index|
        income_types(suffix).values.each_with_index do |income_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank_27g.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)
          members = universe.members.
            # Add youth filter to Q17, but expand universe to include youth adults AND youth
            # heads of household even if they are not adults.
            where(youth_adult_or_youth_hoh_clause)

          answer.update(summary: 0) and next if members.count.zero?

          if income_clause.is_a?(Hash)
            members = members.where.contains(income_clause)
          elsif income_clause.is_a?(Array)
            ids = Set.new
            income_clause.each do |part|
              ids += members.where.contains(part).pluck(:id)
            end
            members = members.where(id: ids.to_a)
          else
            # The final question doesn't require accessing the jsonb column
            members = members.where(income_clause)
          end
          members = members.where(stayers_clause) if suffix == :annual_assessment
          members = members.where(leavers_clause) if suffix == :exit
          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    private def q27h_youth_earned_income
      table_name = 'Q27h'
      metadata = {
        header_row: ['Number of Youth By Income Category'] + q27h_populations.keys,
        row_labels: income_headers_27h,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 12,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q27h_populations.values.each_with_index do |suffix, col_index|
        income_responses(suffix).values.each_with_index do |income_case, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank_27h.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)
          youth = universe.members.
            where(youth_adult_or_youth_hoh_clause)
          youth = youth.where(stayers_clause) if suffix == :annual_assessment
          youth = youth.where(leavers_clause) if suffix == :exit

          ids = Set.new
          if income_case.is_a?(Symbol)
            youth.preload(:universe_membership).find_each do |member|
              apr_client = member.universe_membership
              case income_case
              when :earned
                ids << member.id if earned_income?(apr_client, suffix) && ! other_income?(apr_client, suffix)
              when :other
                ids << member.id if other_income?(apr_client, suffix) && ! earned_income?(apr_client, suffix)
              when :both
                ids << member.id if both_income_types?(apr_client, suffix)
              when :none
                ids << member.id if no_income?(apr_client, suffix)
              end
            end
            members = youth.where(id: ids)
          else
            members = youth.where(income_case)
          end

          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    private def q27i_youth_disabling_conditions
      table_name = 'Q27i'
      metadata = {
        header_row: [' '] + q27i_disabilities.keys,
        row_labels: q27i_income_sources.keys,
        first_column: 'B',
        last_column: 'Q',
        first_row: 2,
        last_row: 18,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q27i_disabilities.values.each_with_index do |disabilities_clause, col_index|
        q27i_income_sources.values.each_with_index do |income_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank_q27i.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)
          members = universe.members.
            # Only relevant to youth or < 24 HoH leavers with answers for income at exit and disability
            where(youth_adult_or_youth_hoh_clause).
            where(leavers_clause).
            where(a_t[:disabling_condition].in([0, 1])).
            where(a_t[:income_from_any_source_at_exit].in([0, 1]))

          answer.update(summary: 0) and next if members.count.zero?

          if income_clause.is_a?(Hash)
            members = members.where.contains(income_clause)
          elsif income_clause.is_a?(Array)
            ids = Set.new
            income_clause.each do |part|
              ids += members.where.contains(part).pluck(:id)
            end
            members = members.where(id: ids.to_a)
          else
            # The final question doesn't require accessing the jsonb column
            members = members.where(income_clause)
          end
          value = 0
          if disabilities_clause.is_a?(Hash)
            disabled_count = members.where(disabilities_clause[:household]).
              where(a_t[:disabling_condition].eq(1)).count
            total_count = members.where(disabilities_clause[:household]).count
            value = percentage((disabled_count.to_f / total_count).round(4)) if total_count.positive?
          else
            members = members.where(disabilities_clause)
            value = members.count
          end

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q27i_disabilities
      {
        'AO: Youth with Disabling Condition' => a_t[:disabling_condition].eq(1).
          and(a_t[:household_type].eq(:adults_only)),
        'AO: Youth without Disabling Condition' => a_t[:disabling_condition].eq(0).
          and(a_t[:household_type].eq(:adults_only)),
        'AO: Total Youths' => a_t[:household_type].eq(:adults_only),
        'AO: % with Disabling Condition by Source' => {
          calculation: :percent,
          household: a_t[:household_type].eq(:adults_only),
        },
        'AC: Youth with Disabling Condition' => a_t[:disabling_condition].eq(1).
          and(a_t[:household_type].eq(:adults_and_children)),
        'AC: Youth without Disabling Condition' => a_t[:disabling_condition].eq(0).
          and(a_t[:household_type].eq(:adults_and_children)),
        'AC: Total Youths' => a_t[:household_type].eq(:adults_and_children),
        'AC: % with Disabling Condition by Source' => {
          calculation: :percent,
          household: a_t[:household_type].eq(:adults_and_children),
        },
        'CO: Youth with Disabling Condition' => a_t[:disabling_condition].eq(1).
          and(a_t[:household_type].eq(:children_only)),
        'CO: Youth without Disabling Condition' => a_t[:disabling_condition].eq(0).
          and(a_t[:household_type].eq(:children_only)),
        'CO: Total Youths' => a_t[:household_type].eq(:children_only),
        'CO: % with Disabling Condition by Source' => {
          calculation: :percent,
          household: a_t[:household_type].eq(:children_only),
        },
        'UK: Youth with Disabling Condition' => a_t[:disabling_condition].eq(1).
          and(a_t[:household_type].eq(:unknown)),
        'UK: Youth without Disabling Condition' => a_t[:disabling_condition].eq(0).
          and(a_t[:household_type].eq(:unknown)),
        'UK: Total Youths' => a_t[:household_type].eq(:unknown),
        'UK: % with Disabling Condition by Source' => {
          calculation: :percent,
          household: a_t[:household_type].eq(:unknown),
        },
      }
    end

    private def q27i_income_sources
      other_sources = [
        'Unemployment Insurance',
        'VA Non-Service Connected Disability Pension',
        'General Assistance (GA)',
        'Alimony and other spousal support',
        'Other Source',
      ]

      income_types(:exit).except(
        'Adults with Income Information at Start and Annual Assessment/Exit',
      ).merge(
        {
          'Other Source' => income_types(:exit).slice(*other_sources).values,
          'No Sources' => a_t[:income_from_any_source_at_exit].eq(0),
          'Unduplicated Total Youth' => youth_filter,
        },
      )
    end

    private def q27j_average_length_of_participation
      table_name = 'Q27j'
      metadata = {
        header_row: [' '] + q27j_populations.keys,
        row_labels: q27j_lengths.keys,
        first_column: 'B',
        last_column: 'C',
        first_row: 2,
        last_row: 3,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q27j_populations.values.each_with_index do |population_clause, col_index|
        q27j_lengths.values.each_with_index do |method, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.
            where(population_clause).
            where(youth_filter)
          stay_lengths = members.pluck(a_t[:length_of_stay]).compact
          value = 0
          case method
          when :average
            value = (stay_lengths.sum(0.0) / stay_lengths.count).round(2) if stay_lengths.any?
          when :median
            if stay_lengths.any?
              sorted = stay_lengths.sort
              length = stay_lengths.count
              value = ((sorted[(length - 1) / 2] + sorted[length / 2]) / 2.0).round(2)
            end
          end

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q27k_start_to_move_in
      # members: start_to_move_in_universe
      start_to_move_in_question(
        question: 'Q27k',
        members: universe.members.where(youth_filter),
      )
    end

    private def q27l_time_prior_to_housing
      table_name = 'Q27l'
      metadata = {
        header_row: [' '] + q27l_populations.keys,
        row_labels: q27l_lengths.keys,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 15,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      # 0 (ES-EE); 1 (EE-NbN); 2 (TH); 3 (PSH); 7 (Other) with 2.06 Funding Source of HUD: Pay for Success (35); 8 (SH); 9 (PH); 13 (RRH)
      relevant_members = universe.members.where(a_t[:project_type].in([0, 1, 2, 3, 8, 9, 13]).or(a_t[:pay_for_success].eq(true)))
      q27l_populations.values.each_with_index do |population_clause, col_index|
        q27l_lengths.values.each_with_index do |length_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = relevant_members.where(population_clause).
            where(length_clause).
            where(youth_filter)

          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    def q27m_education_status_youth
      # Youth heads of household who exited from YHDP-funded projects in the report date range
      members = universe.members.where(leavers_clause).where(youth_filter).where(hoh_clause.and(a_t[:age].between(12..24)).and(a_t[:project_type].in([2, 3, 4, 6, 13])))
      question_sheet(question: 'Q27m') do |sheet|
        sheet.add_header(col: 'A', label: 'Current school and attendance')
        sheet.add_header(col: 'B', label: 'At Project Start')
        sheet.add_header(col: 'C', label: 'At Project Exit')

        current_school_attend_rows = [
          ['Not currently enrolled in any school or education course', [0]],
          ['Currently enrolled but not attending regularly', [1]],
          ['Currently enrolled and attending regularly', [2]],
          [label_for(:dkptr), [8, 9]],
          [label_for(:data_not_collected), [99]],
        ]
        current_school_attend_rows.each do |label, values|
          sheet.append_row(label: label) do |row|
            row.append_cell_members(members: members.where(a_t[:current_school_attend_at_entry].in(values)))
            row.append_cell_members(members: members.where(a_t[:current_school_attend_at_exit].in(values)))
          end
        end

        sheet.append_row(label: 'For those not enrolled – most recent education status')
        most_recent_ed_status_rows = [
          ['K12: Graduated from high school', [0]],
          ['K12: Obtained GED', [1]],
          ['K12: Dropped out', [2]],
          ['K12: Suspended', [3]],
          ['K12: Expelled', [4]],
          ['Higher education: Pursuing a credential but not currently attending', [5]],
          ['Higher education: Dropped out', [6]],
          ['Higher education: Obtained a credential/degree', [7]],
          [label_for(:dkptr), [8, 9]],
          [label_for(:data_not_collected), [99]],
        ]
        most_recent_ed_status_rows.each do |label, values|
          sheet.append_row(label: label) do |row|
            row.append_cell_members(members: members.where(a_t[:most_recent_ed_status_at_entry].in(values)))
            row.append_cell_members(members: members.where(a_t[:most_recent_ed_status_at_exit].in(values)))
          end
        end

        sheet.append_row(label: 'For those currently enrolled – current status')
        current_ed_status_rows = [
          ['Pursuing a high school diploma or GED', [0]],
          ['Pursuing Associate Degree', [1]],
          ['Pursuing Bachelor Degree', [2]],
          ['Pursuing Graduate Degree', [3]],
          ['Pursuing other post-secondary credential', [4]],
          [label_for(:dkptr), [8, 9]],
          [label_for(:data_not_collected), [99]],
        ]
        current_ed_status_rows.each do |label, values|
          sheet.append_row(label: label) do |row|
            row.append_cell_members(members: members.where(a_t[:current_ed_status_at_entry].in(values)))
            row.append_cell_members(members: members.where(a_t[:current_ed_status_at_exit].in(values)))
          end
        end

        # unclear how these would be exclusive
        sheet.append_row(label: 'Total') do |row|
          row.append_cell_members(
            members: members.where(
              [
                a_t[:current_school_attend_at_entry].in(current_school_attend_rows.flat_map(&:last)),
                a_t[:most_recent_ed_status_at_entry].in(most_recent_ed_status_rows.flat_map(&:last)),
                a_t[:current_ed_status_at_entry].in(current_ed_status_rows.flat_map(&:last)),
              ].inject(&:or),
            ),
          )
          row.append_cell_members(
            members: members.where(
              [
                a_t[:current_school_attend_at_exit].in(current_school_attend_rows.flat_map(&:last)),
                a_t[:most_recent_ed_status_at_exit].in(most_recent_ed_status_rows.flat_map(&:last)),
                a_t[:current_ed_status_at_exit].in(current_ed_status_rows.flat_map(&:last)),
              ].inject(&:or),
            ),
          )
        end
      end
    end

    private def q27l_lengths
      # PSH/RRH w/ move in date
      # OR project type 7 (other) with Funder 35 (Pay for Success)
      move_in_projects = HudUtility2024.residential_project_type_numbers_by_code[:ph]
      move_in_for_psh = a_t[:project_type].not_in(move_in_projects).and(a_t[:pay_for_success].eq(false)).
        or(a_t[:project_type].in(move_in_projects).or(a_t[:pay_for_success].eq(true)).and(a_t[:move_in_date].lteq(@report.end_date)))
      {
        '7 days or less' => a_t[:approximate_time_to_move_in].between(0..7).
          and(move_in_for_psh),
        '8 to 14 days' => a_t[:approximate_time_to_move_in].between(8..14).
          and(move_in_for_psh),
        '15 to 21 days' => a_t[:approximate_time_to_move_in].between(15..21).
          and(move_in_for_psh),
        '22 to 30 days' => a_t[:approximate_time_to_move_in].between(22..30).
          and(move_in_for_psh),
        '31 to 60 days' => a_t[:approximate_time_to_move_in].between(31..60).
          and(move_in_for_psh),
        '61 to 90 days' => a_t[:approximate_time_to_move_in].between(61..90).
          and(move_in_for_psh),
        '91 to 180 days' => a_t[:approximate_time_to_move_in].between(91..180).
          and(move_in_for_psh),
        '181 to 365 days' => a_t[:approximate_time_to_move_in].between(181..365).
          and(move_in_for_psh),
        '366 to 730 days (1-2 Yrs)' => a_t[:approximate_time_to_move_in].between(366..730).
          and(move_in_for_psh),
        '731 days or more' => a_t[:approximate_time_to_move_in].gteq(731).
          and(move_in_for_psh),
        'Total (persons moved into housing)' => a_t[:approximate_time_to_move_in].not_eq(nil).
          and(a_t[:project_type].not_in(move_in_projects).
            or(a_t[:project_type].in(move_in_projects).
              and(a_t[:move_in_date].lteq(@report.end_date).and(a_t[:date_to_street].lteq(a_t[:move_in_date]))))),
        'Not yet moved into housing' => a_t[:project_type].not_in(move_in_projects).
          and(a_t[:date_to_street].not_eq(nil).
            and(a_t[:date_to_street].lteq(a_t[:first_date_in_program])).
            and(a_t[:approximate_time_to_move_in].eq(nil))).
          or(a_t[:project_type].in(move_in_projects).
            and(a_t[:move_in_date].eq(nil).or(a_t[:move_in_date].gt(@report.end_date)))),
        'Data not collected' => a_t[:project_type].not_in(move_in_projects).
          and(a_t[:date_to_street].eq(nil).or(a_t[:date_to_street].gt(a_t[:first_date_in_program]))).
          or(a_t[:project_type].in(move_in_projects).
            and(a_t[:move_in_date].lteq(@report.end_date).
              and(a_t[:date_to_street].eq(nil).or(a_t[:date_to_street].gt(a_t[:move_in_date]))))),
        'Total persons' => youth_filter,
      }.freeze
    end

    private def q27j_populations
      {
        'Leavers' => leavers_clause,
        'Stayers' => stayers_clause,
      }
    end

    private def q27k_populations
      sub_populations
    end

    private def q27l_populations
      sub_populations
    end

    private def q27j_lengths
      {
        'Average Length' => :average,
        'Median Length' => :median,
      }
    end

    private def q27k_lengths
      {
        '0 to 7 days' => '7 days or less',
        '8 to 14 days' => '8 to 14 days',
        '15 to 21 days' => '15 to 21 days',
        '22 to 30 days' => '22 to 30 days',
        '31 to 60 days' => '31 to 60 days',
        '61 to 90 days' => '61 to 90 days',
        '91 to 180 days' => '91 to 180 days',
        '181 to 365 days' => '181 to 365 days',
        '366 to 730 days (1-2 Yrs)' => '366 to 730 days (1-2 Yrs)',
        '731 to 1,095 days (2-3 Yrs)' => '731 to 1,095 days (2-3 Yrs)',
        '1,096 to 1,460 days (3-4 Yrs)' => '1,096 to 1,460 days (3-4 Yrs)',
        '1,461 to 1,825 days (4-5 Yrs)' => '1,461 to 1,825 days (4-5 Yrs)',
        'More than 1,825 days (> 5 Yrs)' => 'More than 1,825 days (> 5 Yrs)',
        'Data Not Collected' => 'Data Not Collected',
        'Total' => 'Total',
      }.map do |k, label|
        [label, lengths[k]]
      end.to_h
    end

    private def q27_populations
      sub_populations
    end

    private def q27b_populations
      {
        'Total parenting youth' => :parenting_youth,
        'Total children of parenting youth' => :children_of_youth_parents,
        'Total persons' => :members_youth_households,
        'Total Households' => :youth_households,
      }
    end

    private def youth_parent_age_ranges
      {
        'Parent youth < 18' => hoh_clause.and(a_t[:age].between(0..17)),
        'Parent youth 18 to 24' => hoh_clause.and(a_t[:age].between(18..24)),
      }
    end

    private def income_headers_27g
      income_types('').keys
    end

    private def income_headers_27h
      income_responses('').keys.map do |text|
        text.gsub('Adults', 'Youth').gsub('adults', 'youth')
      end
    end

    private def income_stages
      {
        'Income at Start' => :start,
        'Income at Latest Annual Assessment for Stayers' => :annual_assessment,
        'Income at Exit for Leavers' => :exit,
      }
    end

    private def q27c_responses
      {
        'Male' => a_t[:gender_multi].eq('1'),
        'Female' => a_t[:gender_multi].eq('0'),
        'No Single Gender' => a_t[:gender_multi].in(::HudUtility2024.no_single_gender_queries),
        'Questioning' => a_t[:gender_multi].in(::HudUtility2024.questioning_gender_queries),
        'Transgender' => a_t[:gender_multi].in(::HudUtility2024.transgender_gender_queries),
        label_for(:dkptr) => a_t[:gender_multi].in(['8', '9']),
        'Data Not Collected' => a_t[:gender_multi].eq('99'),
        'Total' => youth_filter,
      }.freeze
    end

    private def youth_age_ranges
      {
        '12-17' => a_t[:age].between(12..17).and(a_t[:dob_quality].in([1, 2])),
        '18-24' => a_t[:age].between(18..24).and(a_t[:dob_quality].in([1, 2])),
        label_for(:dkptr) => Arel.sql('0=1'), # Not used in APR
        'Data Not Collected' => Arel.sql('0=1'), # Not used in APR
        'Total' => youth_filter,
      }
    end

    private def q27e_lengths
      {
        '30 days or less' => '30 days or less',
        '31 to 60 days' => '31 to 60 days',
        '61 to 90 days' => '61 to 90 days',
        '91 to 180 days' => '91 to 180 days',
        '181 to 365 days' => '181 to 365 days',
        '366 to 730 days (1-2 Yrs)' => '366 to 730 days (1-2 Yrs)',
        '731 to 1,095 days (2-3 Yrs)' => '731 to 1,095 days (2-3 Yrs)',
        '1,096 to 1,460 days (3-4 Yrs)' => '1,096 to 1,460 days (3-4 Yrs)',
        '1,461 to 1,825 days (4-5 Yrs)' => '1,461 to 1,825 days (4-5 Yrs)',
        'More than 1,825 days (> 5 Yrs)' => 'More than 1,825 days (> 5 Yrs)',
        'Total' => 'Total',
      }.map do |k, label|
        [label, lengths[k]]
      end.to_h
    end

    private def q27f_destinations_headers
      q27f_destinations.keys.map do |label|
        next 'Subtotal' if label.include?('Subtotal')

        label
      end
    end

    private def q27f_destinations
      destination_clauses
    end

    private def ch_income_types(suffix)
      income_responses(suffix).transform_keys do |k|
        k.sub('Adults', 'Chronically Homeless Persons').sub('adult stayers', 'Chronically Homeless Persons')
      end.except('1 or more source of income', 'Adults with Income Information at Start and Annual Assessment/Exit')
    end

    private def ch_income_sources(suffix)
      income_types(suffix).transform_keys do |k|
        k.sub('Adults', 'Chronically Homeless Persons')
      end
    end

    private def q27e_populations
      {
        'Total' => youth_filter,
        'Leavers' => leavers_clause,
        'Stayers' => stayers_clause,
      }
    end

    private def q27f_populations
      {
        'Number of Chronically Homeless Persons at Start' => :start,
        'Number of Chronically Homeless Persons at Annual Assessment (Stayers)' => :annual_assessment,
        'Number of Chronically Homeless Persons at Exit (Leavers)' => :exit,
      }
    end

    private def q27g_populations
      {
        'Income at Start' => :start,
        'Income at Latest Annual Assessment for Stayers' => :annual_assessment,
        'Income at Exit for Leavers' => :exit,
      }
    end

    private def q27h_populations
      {
        'Number of Youth at Start' => :start,
        'Number of Youth at Annual Assessment (Stayers)' => :annual_assessment,
        'Number of Youth at Exit (Leavers)' => :exit,
      }
    end

    private def q27i_destinations
      destination_clauses
    end

    private def q27i_populations
      sub_populations
    end

    private def youth_adult_or_youth_hoh_clause
      a_t[:other_clients_over_25].eq(false).
        and(
          hoh_clause.and(a_t[:age].between(12..24)).
            or(a_t[:age].between(18..24)),
        )
    end

    private def intentionally_blank
      [].freeze
    end

    private def intentionally_blank_27a
      [
        'B4',
        'B5',
        'C2',
        'C4',
        'C5',
        'D4',
        'D5',
        'E3',
        'E4',
        'E5',
        'F3',
        'F4',
        'F5',
        'F6',
      ].freeze
    end

    private def intentionally_blank_27d
      [
        'B2',
        'C2',
        'D2',
        'E2',
        'F2',
        'B9',
        'C9',
        'D9',
        'E9',
        'F9',
        'B18',
        'C18',
        'D18',
        'E18',
        'F18',
      ].freeze
    end

    private def intentionally_blank_27g
      [
        'B17',
      ].freeze
    end

    private def intentionally_blank_27h
      [
        'B8',
        'B9',
        'B12',
        'D8',
        'D9',
      ].freeze
    end

    private def intentionally_blank_q27i
      [
        'E18',
        'I18',
        'M18',
        'Q18',
      ].freeze
    end
  end
end
