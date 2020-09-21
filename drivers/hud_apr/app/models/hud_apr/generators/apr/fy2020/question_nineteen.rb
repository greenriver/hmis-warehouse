###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionNineteen < Base
    QUESTION_NUMBER = 'Question 19'.freeze
    QUESTION_TABLE_NUMBERS = ['Q19a1', 'Q19a2'].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q19a_stayers
      q19b_leavers

      @report.complete(QUESTION_NUMBER)
    end

    private def q19a_stayers
      table_name = 'Q19a1'
      metadata = {
        header_row: ['Income Change by Income Category (Universe: Adult Stayers with Income Information at Start and Annual Assessment)'] + income_stati_stayers.keys,
        row_labels: yes_know_dkn_clauses(a_t[:domestic_violence]).keys,
        first_column: 'B',
        last_column: 'J',
        first_row: 2,
        last_row: 7,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      suffix = :annual_asessment
      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      income_stati_stayers.each_with_index do |(_, column), col_index|
        income_counts.to_a.each_with_index do |(_, income_category), row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)
          adults = universe.members.
            where( # All adult stayers where the head of household has been in the project 365 days or more
              a_t[:head_of_household_id].in(hoh_lts_stayer_ids).
              and(adult_clause.or(a_t[:head_of_household].eq(true))).
              and(stayers_clause),
            ).
            where( # with Income and Sources at start and at Annual Assessment
              a_t[:income_from_any_source_at_start].eq(1).
              and(a_t[:income_from_any_source_at_annual_assessment].eq(1)).
              and(a_t[:income_total_at_start].gt(0)).
              and(a_t[:income_total_at_annual_assessment].gt(0)),
            )
          ids = Set.new
          adults.preload(:universe_membership).find_each do |member|
            apr_client = member.universe_membership

            case column[:column]
            when 'B'
              ids << member.id if income_for_category?(
                apr_client,
                category: income_category,
                suffix: :start,
              ) && ! income_for_category?(
                apr_client,
                category: income_category,
                suffix: suffix,
              )
            when 'C'
              ids << member.id if income_for_category?(
                apr_client,
                category: income_category,
                suffix: :start,
              ) && income_for_category?(
                apr_client,
                category: income_category,
                suffix: suffix,
              ) && income_change(
                apr_client,
                category: income_category,
                initial: :start,
                subsequent: suffix,
              )&.negative?
            when 'D'
              ids << member.id if income_for_category?(
                apr_client,
                category: income_category,
                suffix: :start,
              ) && income_for_category?(
                apr_client,
                category: income_category,
                suffix: suffix,
              ) && income_change(
                apr_client,
                category: income_category,
                initial: :start,
                subsequent: suffix,
              )&.zero?
            when 'E'
              ids << member.id if income_for_category?(
                apr_client,
                category: income_category,
                suffix: :start,
              ) && income_for_category?(
                apr_client,
                category: income_category,
                suffix: suffix,
              ) && income_change(
                apr_client,
                category: income_category,
                initial: :start,
                subsequent: suffix,
              )&.positive?
            when 'F'
              ids << member.id if ! income_for_category?(
                apr_client,
                category: income_category,
                suffix: :start,
              ) && income_for_category?(
                apr_client,
                category: income_category,
                suffix: suffix,
              )
            when 'G'
              ids << member.id if ! income_for_category?(
                apr_client,
                category: income_category,
                suffix: :start,
              ) && ! income_for_category?(
                apr_client,
                category: income_category,
                suffix: suffix,
              )
            when 'H'
              ids << member.id
            when 'I'
              # Include if the income increased (same as E)
              ids << member.id if income_for_category?(
                apr_client,
                category: income_category,
                suffix: :start,
              ) && income_for_category?(
                apr_client,
                category: income_category,
                suffix: suffix,
              ) && income_change(
                apr_client,
                category: income_category,
                initial: :start,
                subsequent: suffix,
              )&.positive?
              # Include if the client gained income (same as F)
              ids << member.id if ! income_for_category?(
                apr_client,
                category: income_category,
                suffix: :start,
              ) && income_for_category?(
                apr_client,
                category: income_category,
                suffix: suffix,
              )
            when 'J'
              # Include if the income increased (same as E)
              ids << member.id if income_for_category?(
                apr_client,
                category: income_category,
                suffix: :start,
              ) && income_for_category?(
                apr_client,
                category: income_category,
                suffix: suffix,
              ) && income_change(
                apr_client,
                category: income_category,
                initial: :start,
                subsequent: suffix,
              )&.positive?
              # Include if the client gained income (same as F)
              ids << member.id if ! income_for_category?(
                apr_client,
                category: income_category,
                suffix: :start,
              ) && income_for_category?(
                apr_client,
                category: income_category,
                suffix: suffix,
              )
            end
          end
          members = adults.where(id: ids)

          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    private def q19b_dv_fleeing
      table_name = 'Q19a2'
      metadata = {
        header_row: ['Income Change by Income Category (Universe: Adult Leavers with Income Information at Start and Exit)'] + income_stati_leavers.keys,
        row_labels: yes_know_dkn_clauses(a_t[:domestic_violence]).keys,
        first_column: 'B',
        last_column: 'J',
        first_row: 2,
        last_row: 7,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      sub_populations.each_with_index do |(_, population_clause), col_index|
        yes_know_dkn_clauses(a_t[:domestic_violence]).each_with_index do |(_, dv_clause), row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"

          answer = @report.answer(question: table_name, cell: cell)
          members = universe.members.
            where(adult_or_hoh_clause). # only valid for HoH and adults
            where(a_t[:currently_fleeing].eq(1)). # Q19b requires currently fleeing
            where(population_clause).
            where(dv_clause)
          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    private def income_stati_stayers
      {
        'Had Income Category at Start and Did Not Have It at Annual Assessment' => { column: 'B' },
        'Retained Income Category But Had Less $ at Annual Assessment Than at Start' => { column: 'C' },
        'Retained Income Category and Same $ at Annual Assessment as at Start' => { column: 'D' },
        'Retained Income Category and Increased $ at Annual Assessment' => { column: 'E' },
        'Did Not Have the Income Category at Start and Gained the Income Category at Annual Assessment' => { column: 'F' },
        'Did Not Have the Income Category at Start or at Annual Assessment' => { column: 'G' },
        'Total Adults (including those with No Income)' => { column: 'H' },
        'Performance Measure: Adults who Gained or Increased Income from Start to Annual Assessment, Average Gain' => { column: 'I' },
        'Performance measure: Percent of persons who accomplishe d this measure' => { column: 'J' },
      }
    end

    private def income_stati_leavers
      {
        'Had Income Category at Start and Did Not Have It at Exit' => { column: 'B' },
        'Retained Income Category But Had Less $ at Exit Than at Start' => { column: 'C' },
        'Retained Income Category and Same $ at Exit as at Start' => { column: 'D' },
        'Retained Income Category and Increased $ at Exit' => { column: 'E' },
        'Did Not Have the Income Category at Start and Gained the Income Category at Exit' => { column: 'F' },
        'Did Not Have the Income Category at Start or at Exit' => { column: 'G' },
        'Total Adults (including those with No Income)' => { column: 'H' },
        'Performance Measure: Adults who Gained or Increased Income from Start to Exit, Average Gain' => { column: 'I' },
        'Performance measure: Percent of persons who accomplished this measure' => { column: 'J' },
      }
    end

    private def income_counts
      {
        'Number of Adults with Earned Income (i.e., Employment Income)' => {
          category: :earned,
          calculation: :count,
        },
        'Average Change in Earned Income' => {
          category: :earned,
          calculation: :sum,
        },
        'Number of Adults with Other Income' => {
          category: :other,
          calculation: :count,
        },
        'Average Change in Other Income' => {
          category: :other,
          calculation: :sum,
        },
        'Number of Adults with Any Income (i.e., Total Income)' => {
          category: :total,
          calculation: :count,
        },
        'Average Change in Overall Income' => {
          category: :total,
          calculation: :sum,
        },
      }
    end

    private def intentionally_blank
      [
        'D3',
        'G3',
        'H3',
        'J3',
        'D5',
        'G5',
        'H5',
        'J5',
        'D7',
        'G7',
        'J7',
      ].freeze
    end

    private def universe
      @universe ||= build_universe(
        QUESTION_NUMBER,
        preloads: {
          enrollment: [
            :client,
            :income_benefits,
            :income_benefits_at_exit,
            :income_benefits_at_entry,
            :income_benefits_annual_update,
          ],
        },
      ) do |_, enrollments|
        last_service_history_enrollment = enrollments.last
        enrollment = last_service_history_enrollment.enrollment
        source_client = enrollment.client
        client_start_date = [@report.start_date, last_service_history_enrollment.first_date_in_program].max
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
          head_of_household: last_service_history_enrollment.head_of_household,
          head_of_household_id: last_service_history_enrollment.head_of_household_id,
          length_of_stay: stay_length(last_service_history_enrollment),
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
        )
      end
    end
  end
end
