###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionTwentySix < Base
    QUESTION_NUMBER = 'Question 26'.freeze
    QUESTION_TABLE_NUMBERS = ['Q26a', 'Q26b', 'Q26c', 'Q26d', 'Q26e', 'Q26f', 'Q26g', 'Q26h'].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    private def q26a_chronic_households
      table_name = 'Q26a'
      metadata = {
        header_row: [' '] + q26_populations.keys,
        row_labels: ch_categories.keys,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 6,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q26_populations.values.each_with_index do |population_clause, col_index|
        households = Set.new
        ch_categories.values.each_with_index do |ch_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          household_ids = universe.members.where(population_clause).
            where(ch_clause).
            distinct.pluck(a_t[:household_id])
          # ignore previously counted households
          household_ids -= households.to_a
          members = universe.members.where(hoh_clause).where(a_t[:household_id].in(household_ids))

          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q26b_chronic_households
      table_name = 'Q26b'
      metadata = {
        header_row: [' '] + q26_populations.keys,
        row_labels: ch_categories.keys,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 6,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q26_populations.values.each_with_index do |population_clause, col_index|
        ch_categories.values.each_with_index do |ch_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(population_clause).where(ch_clause)

          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q26c_ch_gender
      table_name = 'Q26c'
      metadata = {
        header_row: [' '] + q26_populations.keys,
        row_labels: q26c_responses.keys,
        first_column: 'B',
        last_column: 'E',
        first_row: 2,
        last_row: 9,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q26_populations.values.each_with_index do |population_clause, col_index|
        q26c_responses.values.each_with_index do |response_clause, row_index|
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

    private def q26_populations
      @q26_populations ||= sub_populations
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

    private def q26c_responses
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

    private def intentionally_blank
      [].freeze
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
        )
      end
    end
  end
end
