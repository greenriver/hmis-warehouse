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
          next if intentionally_blank_27d.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(only_youth_clause).
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
        youth_parent_age_ranges.values.each_with_index do |response_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          # FIXME: we can't use parenting youth because we need age based
          # on reporting date
          # need to use household_members
          answer = @report.answer(question: table_name, cell: cell)

          population_clause.present?

          members.preload(:universe_membership).find_each do |member|
            apr_client = member.universe_membership
            case response_clause
            when :chronic
              if ! households.include?(apr_client.household_id) && household_veterans_chronically_homeless?(apr_client)
                ids << member.id
                households << apr_client.household_id
              end
            when :not_chronic
              if ! households.include?(apr_client.household_id) && household_veterans_non_chronically_homeless?(apr_client)
                ids << member.id
                households << apr_client.household_id
              end
            when :veteran
              if ! households.include?(apr_client.household_id) && all_household_adults_non_veterans?(apr_client)
                ids << member.id
                households << apr_client.household_id
              end
            when :refused
              if ! households.include?(apr_client.household_id) && household_adults_refused_veterans(apr_client).any?
                ids << member.id
                households << apr_client.household_id
              end
            when :not_collected
              if ! households.include?(apr_client.household_id) && household_adults_missing_veterans(apr_client).any?
                ids << member.id
                households << apr_client.household_id
              end
            end
          end
          members = members.where(id: ids)

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

    # private def q27c_ch_gender
    #   table_name = 'Q27c'
    #   metadata = {
    #     header_row: [' '] + q27_populations.keys,
    #     row_labels: q27c_responses.keys,
    #     first_column: 'B',
    #     last_column: 'F',
    #     first_row: 2,
    #     last_row: 9,
    #   }
    #   @report.answer(question: table_name).update(metadata: metadata)

    #   cols = (metadata[:first_column]..metadata[:last_column]).to_a
    #   rows = (metadata[:first_row]..metadata[:last_row]).to_a
    #   q27_populations.values.each_with_index do |population_clause, col_index|
    #     q27c_responses.values.each_with_index do |response_clause, row_index|
    #       cell = "#{cols[col_index]}#{rows[row_index]}"
    #       next if intentionally_blank.include?(cell)

    #       answer = @report.answer(question: table_name, cell: cell)

    #       members = universe.members.where(a_t[:chronically_homeless].eq(true)).
    #         where(population_clause).
    #         where(response_clause)
    #       value = members.count

    #       answer.add_members(members)
    #       answer.update(summary: value)
    #     end
    #   end
    # end

    # private def q27e_health_conditions
    #   table_name = 'Q27e'
    #   metadata = {
    #     header_row: [' '] + q27e_populations.keys,
    #     row_labels: disability_clauses(:entry).keys,
    #     first_column: 'B',
    #     last_column: 'D',
    #     first_row: 2,
    #     last_row: 9,
    #   }
    #   @report.answer(question: table_name).update(metadata: metadata)

    #   cols = (metadata[:first_column]..metadata[:last_column]).to_a
    #   rows = (metadata[:first_row]..metadata[:last_row]).to_a
    #   q27e_populations.values.each_with_index do |suffix, col_index|
    #     disability_clauses(suffix).values.each_with_index do |response_clause, row_index|
    #       cell = "#{cols[col_index]}#{rows[row_index]}"
    #       next if intentionally_blank.include?(cell)

    #       answer = @report.answer(question: table_name, cell: cell)

    #       members = universe.members.where(a_t[:chronically_homeless].eq(true)).
    #         where(response_clause)
    #       case suffix
    #       when :exit
    #         members = members.where(stayers_clause)
    #       when :latest
    #         members = members.where(leavers_clause)
    #       end

    #       value = members.count

    #       answer.add_members(members)
    #       answer.update(summary: value)
    #     end
    #   end
    # end

    # private def q27f_income
    #   table_name = 'Q27f'
    #   metadata = {
    #     header_row: ['Number of Chronically Homeless Persons By Income Category'] + q27f_populations.keys,
    #     row_labels: ch_income_types(:entry).keys,
    #     first_column: 'B',
    #     last_column: 'D',
    #     first_row: 2,
    #     last_row: 10,
    #   }
    #   @report.answer(question: table_name).update(metadata: metadata)

    #   cols = (metadata[:first_column]..metadata[:last_column]).to_a
    #   rows = (metadata[:first_row]..metadata[:last_row]).to_a
    #   q27f_populations.values.each_with_index do |suffix, col_index|
    #     ch_income_types(suffix).values.each_with_index do |income_case, row_index|
    #       cell = "#{cols[col_index]}#{rows[row_index]}"
    #       next if intentionally_blank_27f.include?(cell)

    #       answer = @report.answer(question: table_name, cell: cell)
    #       adults = universe.members.where(a_t[:chronically_homeless].eq(true))
    #       adults = adults.where(stayers_clause) if suffix == :annual_assessment
    #       adults = adults.where(leavers_clause) if suffix == :exit

    #       ids = Set.new
    #       if income_case.is_a?(Symbol)
    #         adults.preload(:universe_membership).find_each do |member|
    #           apr_client = member.universe_membership
    #           case income_case
    #           when :earned
    #             ids << member.id if earned_income?(apr_client, suffix) && ! other_income?(apr_client, suffix)
    #           when :other
    #             ids << member.id if other_income?(apr_client, suffix) && ! earned_income?(apr_client, suffix)
    #           when :both
    #             ids << member.id if both_income_types?(apr_client, suffix)
    #           when :none
    #             ids << member.id if no_income?(apr_client, suffix)
    #           end
    #         end
    #         members = adults.where(id: ids)
    #       else
    #         members = adults.where(income_case)
    #       end

    #       value = members.count

    #       answer.add_members(members)
    #       answer.update(summary: value)
    #     end
    #   end
    # end

    # private def q27g_income_sources
    #   table_name = 'Q27g'
    #   metadata = {
    #     header_row: [' '] + q27g_populations.keys,
    #     row_labels: ch_income_sources(:entry).keys,
    #     first_column: 'B',
    #     last_column: 'D',
    #     first_row: 2,
    #     last_row: 17,
    #   }
    #   @report.answer(question: table_name).update(metadata: metadata)

    #   cols = (metadata[:first_column]..metadata[:last_column]).to_a
    #   rows = (metadata[:first_row]..metadata[:last_row]).to_a
    #   q27g_populations.values.each_with_index do |suffix, col_index|
    #     ch_income_sources(suffix).values.each_with_index do |income_clause, row_index|
    #       cell = "#{cols[col_index]}#{rows[row_index]}"
    #       next if intentionally_blank_27g.include?(cell)

    #       answer = @report.answer(question: table_name, cell: cell)
    #       members = universe.members.where(a_t[:chronically_homeless].eq(true))

    #       if income_clause.is_a?(Hash)
    #         members = members.where.contains(income_clause)
    #       else
    #         # The final question doesn't require accessing the jsonb column
    #         members = members.where(income_clause)
    #       end
    #       members = members.where(stayers_clause) if suffix == :annual_assessment
    #       members = members.where(leavers_clause) if suffix == :exit

    #       value = members.count

    #       answer.add_members(members)
    #       answer.update(summary: value)
    #     end
    #   end
    # end

    # private def q27h_non_cash_benefits
    #   table_name = 'Q27h'
    #   metadata = {
    #     header_row: [' '] + q27h_populations.keys,
    #     row_labels: non_cash_benefit_types(:entry).keys,
    #     first_column: 'B',
    #     last_column: 'D',
    #     first_row: 2,
    #     last_row: 7,
    #   }
    #   @report.answer(question: table_name).update(metadata: metadata)

    #   cols = (metadata[:first_column]..metadata[:last_column]).to_a
    #   rows = (metadata[:first_row]..metadata[:last_row]).to_a

    #   q27h_populations.values.each_with_index do |suffix, col_index|
    #     non_cash_benefit_types(suffix).values.each_with_index do |income_clause, row_index|
    #       cell = "#{cols[col_index]}#{rows[row_index]}"
    #       next if intentionally_blank.include?(cell)

    #       answer = @report.answer(question: table_name, cell: cell)

    #       members = universe.members.where(a_t[:chronically_homeless].eq(true))
    #       case suffix
    #       when :annual_assessment
    #         members = members.where(stayers_clause).
    #           where(a_t[:annual_assessment_expected].eq(true))
    #       when :exit
    #         # non-HoH clients are limited to those who exited on or after the HoH
    #         # For leavers, report only heads of households who left plus other adult household members who left at the same time as the head of household. Do not include household members who left prior to the head of household even though that person is otherwise considered a “leaver” in other report questions.
    #         additional_leaver_ids = Set.new
    #         members.where(leavers_clause).where(a_t[:head_of_household].eq(false)).
    #           pluck(a_t[:id], a_t[:head_of_household_id], a_t[:last_date_in_program]).each do |id, hoh_id, exit_date|
    #             hoh_exit_date = hoh_exit_dates[hoh_id]
    #             additional_leaver_ids << id if exit_date.blank? || hoh_exit_date.blank? || exit_date >= hoh_exit_date
    #           end
    #         members = members.where(leavers_clause).where(hoh_clause.or(a_t[:id].in(additional_leaver_ids)))
    #       end

    #       members = members.where.contains(income_clause)
    #       value = members.count

    #       answer.add_members(members)
    #       answer.update(summary: value)
    #     end
    #   end
    # end

    private def only_youth_clause
      a_t[:age].between(12..24).and(a_t[:other_clients_over_25].eq(0))
    end

    private def parenting_non_adult_clause
      hoh_clause.and(a_t[:parenting_youth].eq(true).or(a_t[:parenting_juvenile].eq(true)))
    end

    private def member_of_youth_parent_household
      a_t[:parenting_youth].eq(false).
        and(a_t[:parenting_juvenile].eq(false)).
        and(
          a_t[:household_id].in(
            HudApr::Fy2020::AprClient.where(parenting_non_adult_clause).select(:household_id),
          ),
        )
    end

    private def child_of_youth_clause
      member_of_youth_parent_household.and(a_t[:relationship_to_hoh].eq(2))
    end

    private def q27_populations
      @q27_populations ||= sub_populations
    end

    private def q27b_populations
      {
        'Total parenting youth' => parenting_non_adult_clause,
        'Total children of parenting youth' => child_of_youth_clause,
      }
    end

    private def youth_parent_age_ranges
      {
        'Parent youth < 18' => a_t[:parenting_juvenile].eq(true),
        'Parent youth 18 to 24' => a_t[:parenting_youth].eq(true),
        'Total persons' => parenting_non_adult_clause.or(member_of_youth_parent_household),
        'Total Households' => :household_count,
      }
    end

    private def ch_categories
      {
        'Chronically Homeless' => a_t[:chronically_homeless].eq(true),
        'Not Chronically Homeless' => a_t[:chronically_homeless].eq(false),
        'Client Doesn’t Know/Client Refused' => a_t[:prior_living_situation].in([8, 9]),
        'Data Not Collected' => a_t[:prior_living_situation].eq(99),
        'Total' => Arel.sql('1=1'),
      }.freeze
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
        'Conditions At Start' => :entry,
        'Conditions at Latest Assessment for Stayers' => :latest,
        'Conditions at Exit for Leavers' => :exit,
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
        'Benefit at Start' => :start,
        'Benefit at Latest Annual Assessment for Stayers' => :annual_assessment,
        'Benefit at Exit for Leavers' => :exit,
      }
    end

    private def q27i_destinations
      destination_clauses
    end

    private def q27i_populations
      @q27i_populations ||= sub_populations
    end

    private def intentionally_blank
      [].freeze
    end

    private def intentionally_blank_27d
      [
        'C2',
        'E3',
      ].freeze
    end

    private def intentionally_blank_27f
      [
        'B8',
        'B9',
        'D8',
        'D9',
      ].freeze
    end

    private def intentionally_blank_27g
      [
        'B17',
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
