###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionTwentyFive < Base
    QUESTION_NUMBER = 'Question 25'.freeze
    QUESTION_TABLE_NUMBERS = ['Q25a', 'Q25b', 'Q25c', 'Q25d', 'Q25e', 'Q25f', 'Q25g', 'Q25h', 'Q25i'].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    private def q25a_number_of_veterans
      table_name = 'Q25a'
      metadata = {
        header_row: [' '] + q25_populations.keys,
        row_labels: q25a_responses.keys,
        first_column: 'B',
        last_column: 'E',
        first_row: 2,
        last_row: 7,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q25_populations.values.each_with_index do |population_clause, col_index|
        q25a_responses.values.each_with_index do |response_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(population_clause).where(response_clause)
          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q25b_number_of_households
      # NOTE: CH Status == prior_living_situation in respect to 8, 9, 99

      table_name = 'Q25b'
      metadata = {
        header_row: [' '] + q25_populations.keys,
        row_labels: q25b_responses.keys,
        first_column: 'B',
        last_column: 'E',
        first_row: 2,
        last_row: 7,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q25_populations.values.each_with_index do |population_clause, col_index|
        households = Set.new # only count each household once
        q25b_responses.values.each_with_index do |response_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)
          members = universe.members.where(hoh_clause).where(population_clause)

          ids = Set.new
          if response_clause.is_a?(Symbol)
            # Count any households where any adult or HoH in the household
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
          else
            members = members.where(a_t[:household_id].in(households.to_a))
          end

          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q25c_veteran_gender
      table_name = 'Q25c'
      metadata = {
        header_row: [' '] + q25_populations.keys,
        row_labels: q25c_responses.keys,
        first_column: 'B',
        last_column: 'E',
        first_row: 2,
        last_row: 9,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q25_populations.values.each_with_index do |population_clause, col_index|
        q25c_responses.values.each_with_index do |response_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(a_t[:veteran_status].eq(1)).
            where(population_clause).
            where(response_clause)
          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q25d_veteran_age
      table_name = 'Q25d'
      metadata = {
        header_row: [' '] + q25_populations.keys,
        row_labels: veteran_age_ranges.keys,
        first_column: 'B',
        last_column: 'E',
        first_row: 2,
        last_row: 10,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q25_populations.values.each_with_index do |population_clause, col_index|
        veteran_age_ranges.values.each_with_index do |response_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(veteran_clause).
            where(population_clause).
            where(response_clause)
          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q25e_health_conditions
      table_name = 'Q25e'
      metadata = {
        header_row: [' '] + q25e_populations.keys,
        row_labels: disability_clauses(:entry).keys,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 9,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q25e_populations.values.each_with_index do |suffix, col_index|
        disability_clauses(suffix).values.each_with_index do |response_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(veteran_clause).
            where(response_clause)
          case suffix
          when :exit
            members = members.where(stayers_clause)
          when :latest
            members = members.where(leavers_clause)
          end

          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q25f_income
      table_name = 'Q25f'
      metadata = {
        header_row: [' '] + q25f_populations.keys,
        row_labels: veteran_income_types(:entry).keys,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 10,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q25f_populations.values.each_with_index do |suffix, col_index|
        veteran_income_types(suffix).values.each_with_index do |income_case, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)
          adults = universe.members.where(veteran_clause)
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

          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q25g_income_sources
      table_name = 'Q25g'
      metadata = {
        header_row: [' '] + q25g_populations.keys,
        row_labels: veteran_income_sources(:entry).keys,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 17,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q25g_populations.values.each_with_index do |suffix, col_index|
        veteran_income_sources(suffix).values.each_with_index do |income_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank_25g.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)
          members = universe.members.where(veteran_clause)

          if income_clause.is_a?(Hash)
            members = members.where.contains(income_clause)
          else
            # The final question doesn't require accessing the jsonb column
            members = members.where(income_clause)
          end
          members = members.where(stayers_clause) if suffix == :annual_assessment
          members = members.where(leavers_clause) if suffix == :exit

          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q25h_non_cash_benefits
      table_name = 'Q25h'
      metadata = {
        header_row: [' '] + q25h_populations.keys,
        row_labels: non_cash_benefit_types(:entry).keys,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 7,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a

      q25h_populations.values.each_with_index do |suffix, col_index|
        non_cash_benefit_types(suffix).values.each_with_index do |income_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(veteran_clause)
          case suffix
          when :annual_assessment
            members = members.where(stayers_clause).
              where(a_t[:annual_assessment_expected].eq(true))
          when :exit
            # non-HoH clients are limited to those who exited on or after the HoH
            # For leavers, report only heads of households who left plus other adult household members who left at the same time as the head of household. Do not include household members who left prior to the head of household even though that person is otherwise considered a “leaver” in other report questions.
            additional_leaver_ids = Set.new
            members.where(leavers_clause).where(a_t[:head_of_household].eq(false)).
              pluck(a_t[:id], a_t[:head_of_household_id], a_t[:last_date_in_program]).each do |id, hoh_id, exit_date|
                hoh_exit_date = hoh_exit_dates[hoh_id]
                additional_leaver_ids << id if exit_date.blank? || hoh_exit_date.blank? || exit_date >= hoh_exit_date
              end
            members = members.where(leavers_clause).where(hoh_clause.or(a_t[:id].in(additional_leaver_ids)))
          end

          members = members.where.contains(income_clause)
          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q25i_destination
      table_name = 'Q25i'
      metadata = {
        header_row: [' '] + q25i_populations.keys,
        row_labels: q25i_destinations_headers,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 46,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q25i_populations.values.each_with_index do |population_clause, col_index|
        q25i_destinations.values.each_with_index do |destination_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank_25i.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)
          value = 0

          if destination_clause.is_a?(Symbol)
            case destination_clause
            when :percentage
              members = universe.members.where(population_clause)
              positive = members.where(q25i_destinations['Total persons exiting to positive housing destinations']).count
              total = members.count
              excluded = members.where(q25i_destinations['Total persons whose destinations excluded them from the calculation']).count
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

    private def veteran_age_ranges
      age_ranges.except('Under 5', '5-12', '13-17')
    end

    private def q25e_populations
      {
        'Conditions At Start' => :entry,
        'Conditions at Latest Assessment for Stayers' => :latest,
        'Conditions at Exit for Leavers' => :exit,
      }
    end

    private def q25_populations
      sub_populations.except('With Only Children')
    end

    private def q25a_responses
      {
        'Chronically Homeless Veteran' => a_t[:chronically_homeless].eq(true).and(a_t[:veteran_status].eq(1)),
        'Non-Chronically Homeless Veteran' => a_t[:chronically_homeless].eq(false).and(a_t[:veteran_status].eq(1)),
        'Not a Veteran' => a_t[:veteran_status].eq(0),
        "Client Doesn't Know/Client Refused" => a_t[:veteran_status].in([8, 9]),
        'Data Not Collected' => a_t[:veteran_status].eq(99),
        'Total' => Arel.sql('1=1'),
      }.freeze
    end

    private def q25b_responses
      {
        'Chronically Homeless Veteran' => :chronic,
        'Non-Chronically Homeless Veteran' => :not_chronic,
        'Not a Veteran' => :veteran,
        "Client Doesn't Know/Client Refused" => :refused,
        'Data Not Collected' => :not_collected,
        'Total' => Arel.sql('1=1'),
      }.freeze
    end

    private def q25c_responses
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

    private def veteran_income_types(suffix)
      income_responses(suffix).transform_keys do |k|
        k.sub('Adults', 'Veterans').sub('adult stayers', 'veterans')
      end.except('1 or more source of income', 'Adults with Income Information at Start and Annual Assessment/Exit')
    end

    private def veteran_income_sources(suffix)
      income_types(suffix).transform_keys do |k|
        k.sub('Adults', 'Veterans')
      end
    end

    private def q25f_populations
      {
        'Number of Veterans at Start' => :start,
        'Number of Veterans at Annual Assessment (Stayers)' => :annual_assessment,
        'Number of Veterans at Exit (Leavers)' => :exit,
      }
    end

    private def q25g_populations
      {
        'Income at Start' => :start,
        'Income at Latest Annual Assessment for Stayers' => :annual_assessment,
        'Income at Exit for Leavers' => :exit,
      }
    end

    private def q25h_populations
      {
        'Benefit at Start' => :start,
        'Benefit at Latest Annual Assessment for Stayers' => :annual_assessment,
        'Benefit at Exit for Leavers' => :exit,
      }
    end

    private def q25i_destinations
      destination_clauses
    end

    private def q25i_populations
      sub_populations
    end

    private def q25i_destinations_headers
      q25i_destinations.keys.map do |label|
        next 'Subtotal' if label.include?('Subtotal')

        label
      end
    end

    private def intentionally_blank
      [].freeze
    end

    private def intentionally_blank_25g
      [
        'B17',
      ].freeze
    end

    private def intentionally_blank_25i
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

    private def universe # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
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
          first_date_in_program: last_service_history_enrollment.first_date_in_program,
          last_date_in_program: last_service_history_enrollment.last_date_in_program,
          head_of_household: last_service_history_enrollment[:head_of_household],
          head_of_household_id: last_service_history_enrollment.head_of_household_id,
          household_type: @household_types[last_service_history_enrollment.household_id],
          project_type: last_service_history_enrollment.computed_project_type,
          veteran_status: source_client.VeteranStatus,
          chronically_homeless: enrollment.chronically_homeless_at_start?,
          destination: last_service_history_enrollment.destination,
          household_id: last_service_history_enrollment.household_id,

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
