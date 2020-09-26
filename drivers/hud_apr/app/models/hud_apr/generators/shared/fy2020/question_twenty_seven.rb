###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionTwentySeven < Base
    QUESTION_NUMBER = 'Question 27'.freeze
    QUESTION_TABLE_NUMBERS = ['Q27a', 'Q27b', 'Q27c', 'Q27d', 'Q27e', 'Q27f', 'Q27g', 'Q27h'].freeze

    def self.question_number
      QUESTION_NUMBER
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
      q27_populations.values.each_with_index do |population_clause, col_index|
        youth_age_ranges.values.each_with_index do |response_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(population_clause).
            where(response_clause)
          # because we need to use the age for the given enrollment within the context of the report
          # we need to further limit this to only clients who are in households with only youth
          ids = Set.new
          members.preload(:universe_membership).find_each do |member|
            apr_client = member.universe_membership
            ids << member.id if only_youth?(apr_client)
          end
          members = members.where(id: ids)
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
        row_labels: youth_age_ranges.keys,
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
            a_t[:household_id].in(universe.members.where(response_clause).select(a_t[:household_id])),
          )

          source_client_ids = Set.new
          members.preload(:universe_membership).find_each do |member|
            apr_client = member.universe_membership
            case population_clause
            when :parenting_youth
              # We haven't already counted this household, the client is an HoH and all members are youth
              # report HoH and adults (18-24)
              if ! households.include?(apr_client.household_id) && youth_parent?(apr_client)
                # since apr_client is the HoH and we've already limited to only youth households,
                # we can safely return the adults and the source client id of the apr_client
                adult_ids = adult_source_client_ids(apr_client)
                adult_ids << apr_client.client_id
                source_client_ids += adult_ids
                households << apr_client.household_id
              end
            when :children_of_youth_parents
              # Find source client ids where the HoH is a youth and the members are RelationshipToHoH == 2
              if ! households.include?(apr_client.household_id) && youth_parent?(apr_client)
                source_client_ids += youth_child_source_client_ids(apr_client)
                households << apr_client.household_id
              end
            when :members_youth_households
              # Return all clients within the household, regardless of relationship
              if ! households.include?(apr_client.household_id) && youth_parent?(apr_client)
                source_client_ids += apr_client.household_members.map { |m| m['source_client_id'] }
                households << apr_client.household_id
              end
            when :youth_households
              # Use the HoH as a proxy for household
              if ! households.include?(apr_client.household_id) && youth_parent?(apr_client)
                source_client_ids += apr_client.client_id
                households << apr_client.household_id
              end
            end
          end

          members = members.where(client_id: source_client_ids) if source_client_ids.any?

          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    # private def q27a_chronic_households
    #   table_name = 'Q27a'
    #   metadata = {
    #     header_row: [' '] + q27_populations.keys,
    #     row_labels: ch_categories.keys,
    #     first_column: 'B',
    #     last_column: 'F',
    #     first_row: 2,
    #     last_row: 6,
    #   }
    #   @report.answer(question: table_name).update(metadata: metadata)

    #   cols = (metadata[:first_column]..metadata[:last_column]).to_a
    #   rows = (metadata[:first_row]..metadata[:last_row]).to_a
    #   q27_populations.values.each_with_index do |population_clause, col_index|
    #     households = Set.new
    #     ch_categories.values.each_with_index do |ch_clause, row_index|
    #       cell = "#{cols[col_index]}#{rows[row_index]}"
    #       next if intentionally_blank.include?(cell)

    #       answer = @report.answer(question: table_name, cell: cell)

    #       household_ids = universe.members.where(population_clause).
    #         where(ch_clause).
    #         distinct.pluck(a_t[:household_id])
    #       # ignore previously counted households
    #       household_ids -= households.to_a
    #       members = universe.members.where(hoh_clause).where(a_t[:household_id].in(household_ids))

    #       value = members.count

    #       answer.add_members(members)
    #       answer.update(summary: value)
    #     end
    #   end
    # end

    # private def q27b_chronic_households
    #   table_name = 'Q27b'
    #   metadata = {
    #     header_row: [' '] + q27_populations.keys,
    #     row_labels: ch_categories.keys,
    #     first_column: 'B',
    #     last_column: 'F',
    #     first_row: 2,
    #     last_row: 6,
    #   }
    #   @report.answer(question: table_name).update(metadata: metadata)

    #   cols = (metadata[:first_column]..metadata[:last_column]).to_a
    #   rows = (metadata[:first_row]..metadata[:last_row]).to_a
    #   q27_populations.values.each_with_index do |population_clause, col_index|
    #     ch_categories.values.each_with_index do |ch_clause, row_index|
    #       cell = "#{cols[col_index]}#{rows[row_index]}"
    #       next if intentionally_blank.include?(cell)

    #       answer = @report.answer(question: table_name, cell: cell)

    #       members = universe.members.where(population_clause).where(ch_clause)

    #       value = members.count

    #       answer.add_members(members)
    #       answer.update(summary: value)
    #     end
    #   end
    # end

    private def q27c_youth_gender
      table_name = 'Q27c'
      metadata = {
        header_row: [' '] + q27_populations.keys,
        row_labels: q27c_responses.keys,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 9,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q27_populations.values.each_with_index do |population_clause, col_index|
        q27c_responses.values.each_with_index do |response_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(a_t[:age].between(0..24)).
            where(population_clause).
            where(response_clause)
          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q27d_youth_living_situation
      table_name = 'Q27d'
      metadata = {
        header_row: [' '] + q27_populations.keys,
        row_labels: living_situation_headers,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 35,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q27_populations.values.each_with_index do |population_clause, col_index|
        living_situations.values.each_with_index do |situation_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank_27d.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)
          members = universe.members.
            where(hoh_clause.and(a_t[:age].in(0..24))).
            where(population_clause).
            where(situation_clause)
          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    private def q27e_youth_length_of_participation
      table_name = 'Q27e'
      metadata = {
        header_row: [' '] + q27e_populations.keys,
        row_labels: q27e_lengths.keys,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 13,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q27e_populations.values.each_with_index do |population_clause, col_index|
        q27e_lengths.values.each_with_index do |length_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(a_t[:age].between(0..24)).
            where(population_clause).
            where(length_clause)

          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    private def q27f_youth_destination
      table_name = 'Q27f'
      metadata = {
        header_row: [' '] + q27_populations.keys,
        row_labels: q27f_destinations_headers,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 46,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q27_populations.values.each_with_index do |population_clause, col_index|
        q27f_destinations.values.each_with_index do |destination_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank_27f.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)
          value = 0

          if destination_clause.is_a?(Symbol)
            case destination_clause
            when :percentage
              members = universe.members.where(population_clause)
              positive = members.where(q27f_destinations['Total persons exiting to positive housing destinations']).count
              total = members.count
              excluded = members.where(q27f_destinations['Total persons whose destinations excluded them from the calculation']).count
              value = (positive.to_f / (total - excluded) * 100).round(4) if total.positive? && excluded != total
            end
          else
            members = universe.members.where(population_clause).where(destination_clause)
            value = members.count
          end
          answer.add_members(members)
          answer.update(summary: value)
        end
      end
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
            where(hoh_clause.and(a_t[:age].between(0..24)).or(a_t[:age].between(18..24)))
          if income_clause.is_a?(Hash)
            members = members.where.contains(income_clause)
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
          adults = universe.members.where(adult_clause)
          adults = adults.where(stayers_clause) if suffix == :annual_assessment
          adults = adults.where(leavers_clause) if suffix == :exit

          ids = Set.new
          if income_case.is_a?(Symbol)
            adults.preload(:universe_membership).find_each do |member|
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
            members = adults.where(id: ids)
          else
            members = adults.where(income_case)
          end

          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    private def q27i_youth_disabling_conditions
      # FIXME
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

    private def living_situation_headers
      living_situations.keys.map do |label|
        next 'Subtotal' if label.include?('Subtotal')

        label
      end
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
        'Male' => a_t[:gender].eq(1),
        'Female' => a_t[:gender].eq(0),
        'Trans Female (MTF or Male to Female)' => a_t[:gender].eq(2),
        'Trans Male (FTM or Female to Male)' => a_t[:gender].eq(3),
        'Gender Non-Conforming (i.e. not exclusively male or female)' => a_t[:gender].eq(4),
        "Client Doesn't Know/Client Refused" => a_t[:gender].in([8, 9]),
        'Data Not Collected' => a_t[:gender].eq(99).or(a_t[:gender].eq(nil)),
        'Total' => Arel.sql('1=1'),
      }.freeze
    end

    private def youth_age_ranges
      {
        '12-17' => a_t[:age].between(12..17),
        '18-24' => a_t[:age].between(18..24),
        "Client Doesn't Know/Client Refused" => a_t[:dob_quality].in([8, 9]),
        'Data Not Collected' => a_t[:dob_quality].not_in([8, 9]).and(a_t[:dob_quality].eq(99).or(a_t[:dob_quality].eq(nil)).or(a_t[:age].lt(0)).or(a_t[:age].eq(nil))),
        'Total' => Arel.sql('1=1'), # include everyone
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
        'Data Not Collected' => 'Data Not Collected',
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
        'Total' => Arel.sql('1=1'),
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

    private def intentionally_blank
      [].freeze
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

    private def intentionally_blank_27f
      [
        'B2',
        'C2',
        'D2',
        'E2',
        'F2',
        'B17',
        'C17',
        'D17',
        'E17',
        'F17',
        'B28',
        'C28',
        'D28',
        'E28',
        'F28',
        'B36',
        'C36',
        'D36',
        'E36',
        'F36',
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

    private def universe # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      batch_initializer = ->(clients_with_enrollments) do
        @household_types = {}
        clients_with_enrollments.each do |_, enrollments|
          last_service_history_enrollment = enrollments.last
          hh_id = last_service_history_enrollment.household_id
          @household_types[hh_id] = household_makeup(hh_id, [@report.start_date, last_service_history_enrollment.first_date_in_program].max)
        end
      end

      @universe ||= build_universe(
        QUESTION_NUMBER,
        before_block: batch_initializer,
        preloads: {
          enrollment: [
            :client,
            :income_benefits,
            :income_benefits_at_exit,
            :income_benefits_at_entry,
            :income_benefits_annual_update,
            :disabilities,
            :project,
          ],
        },
      ) do |_, enrollments|
        last_service_history_enrollment = enrollments.last
        enrollment = last_service_history_enrollment.enrollment
        source_client = enrollment.client
        client_start_date = [@report.start_date, last_service_history_enrollment.first_date_in_program].max

        disabilities_at_entry = enrollment.disabilities.select { |d| d.DataCollectionStage == 1 }
        disabilities_at_exit = enrollment.disabilities.select { |d| d.DataCollectionStage == 3 }
        max_disability_date = enrollment.disabilities.select { |d| d.InformationDate <= @report.end_date }.
          map(&:InformationDate).max
        disabilities_latest = enrollment.disabilities.select { |d| d.InformationDate == max_disability_date }

        exit_date = last_service_history_enrollment.last_date_in_program
        exit_record = last_service_history_enrollment.enrollment if exit_date.present? && exit_date < @report.end_date

        income_at_start = enrollment.income_benefits_at_entry
        income_at_annual_assessment = annual_assessment(enrollment)
        income_at_exit = exit_record&.income_benefits_at_exit

        report_client_universe.new(
          client_id: source_client.id,
          data_source_id: source_client.data_source_id,
          report_instance_id: @report.id,

          age: source_client.age_on(client_start_date),
          gender: source_client.Gender,
          first_date_in_program: last_service_history_enrollment.first_date_in_program,
          last_date_in_program: last_service_history_enrollment.last_date_in_program,
          head_of_household: last_service_history_enrollment[:head_of_household],
          head_of_household_id: last_service_history_enrollment.head_of_household_id,
          household_type: @household_types[last_service_history_enrollment.household_id],
          household_id: last_service_history_enrollment.household_id,
          project_type: last_service_history_enrollment.computed_project_type,

          veteran_status: source_client.VeteranStatus,
          prior_living_situation: enrollment.LivingSituation,
          length_of_stay: stay_length(last_service_history_enrollment),
          chronically_homeless: last_service_history_enrollment.enrollment.chronically_homeless_at_start?,
          parenting_youth: last_service_history_enrollment.parenting_youth,
          parenting_juvenile: last_service_history_enrollment.parenting_juvenile,
          other_clients_over_25: last_service_history_enrollment.other_clients_over_25,
          relationship_to_hoh: enrollment.RelationshipToHoH,

          disabling_condition: enrollment.DisablingCondition,
          developmental_disability_entry: disabilities_at_entry.detect(&:developmental?)&.DisabilityResponse,
          hiv_aids_entry: disabilities_at_entry.detect(&:hiv?)&.DisabilityResponse,
          physical_disability_entry: disabilities_at_entry.detect(&:physical?)&.DisabilityResponse,
          chronic_disability_entry: disabilities_at_entry.detect(&:chronic?)&.DisabilityResponse,
          mental_health_problem_entry: disabilities_at_entry.detect(&:mental?)&.DisabilityResponse,
          substance_abuse_entry: disabilities_at_entry.detect(&:substance?)&.DisabilityResponse,
          alcohol_abuse_entry: disabilities_at_entry.detect(&:substance?)&.DisabilityResponse == 1,
          drug_abuse_entry: disabilities_at_entry.detect(&:substance?)&.DisabilityResponse == 2,
          developmental_disability_exit: disabilities_at_exit.detect(&:developmental?)&.DisabilityResponse,
          hiv_aids_exit: disabilities_at_exit.detect(&:hiv?)&.DisabilityResponse,
          physical_disability_exit: disabilities_at_exit.detect(&:physical?)&.DisabilityResponse,
          chronic_disability_exit: disabilities_at_exit.detect(&:chronic?)&.DisabilityResponse,
          mental_health_problem_exit: disabilities_at_exit.detect(&:mental?)&.DisabilityResponse,
          substance_abuse_exit: disabilities_at_exit.detect(&:substance?)&.DisabilityResponse,
          alcohol_abuse_exit: disabilities_at_exit.detect(&:substance?)&.DisabilityResponse == 1,
          drug_abuse_exit: disabilities_at_exit.detect(&:substance?)&.DisabilityResponse == 2,
          developmental_disability_latest: disabilities_latest.detect(&:developmental?)&.DisabilityResponse,
          hiv_aids_latest: disabilities_latest.detect(&:hiv?)&.DisabilityResponse,
          physical_disability_latest: disabilities_latest.detect(&:physical?)&.DisabilityResponse,
          chronic_disability_latest: disabilities_latest.detect(&:chronic?)&.DisabilityResponse,
          mental_health_problem_latest: disabilities_latest.detect(&:mental?)&.DisabilityResponse,
          substance_abuse_latest: disabilities_latest.detect(&:substance?)&.DisabilityResponse,
          alcohol_abuse_latest: disabilities_latest.detect(&:substance?)&.DisabilityResponse == 1,
          drug_abuse_latest: disabilities_latest.detect(&:substance?)&.DisabilityResponse == 2,

          annual_assessment_expected: annual_assessment_expected?(last_service_history_enrollment),
          income_from_any_source_at_start: income_at_start&.IncomeFromAnySource,
          income_from_any_source_at_annual_assessment: income_at_annual_assessment&.IncomeFromAnySource,
          income_from_any_source_at_exit: income_at_exit&.IncomeFromAnySource,
          income_total_at_start: income_at_start&.hud_total_monthly_income,
          income_total_at_annual_assessment: income_at_annual_assessment&.hud_total_monthly_income,
          income_total_at_exit: income_at_exit&.hud_total_monthly_income,
          income_sources_at_start: income_sources(income_at_start),
          income_sources_at_annual_assessment: income_sources(income_at_annual_assessment),
          income_sources_at_exit: income_sources(income_at_exit),
          non_cash_benefits_from_any_source_at_start: income_at_start&.BenefitsFromAnySource,
          non_cash_benefits_from_any_source_at_annual_assessment: income_at_annual_assessment&.BenefitsFromAnySource,
          non_cash_benefits_from_any_source_at_exit: income_at_exit&.BenefitsFromAnySource,

          household_members: household_member_data(last_service_history_enrollment),
        )
      end
    end
  end
end
