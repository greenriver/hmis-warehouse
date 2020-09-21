###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Apr::Fy2020
  class QuestionNineteen < HudApr::Generators::Shared::Fy2020::Base
    QUESTION_NUMBER = 'Question 19'.freeze
    QUESTION_TABLE_NUMBERS = ['Q19a1', 'Q19a2'].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q19a_stayers
      q19a_leavers

      @report.complete(QUESTION_NUMBER)
    end

    private def q19a(table_name, metadata, income_status_method:, suffix:, inclusion_clause:)
      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      send(income_status_method).each_with_index do |(_, column), col_index|
        income_counts.to_a.each_with_index do |(_, income_options), row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          income_category = income_options[:category]
          calculation = income_options[:calculation]
          answer = @report.answer(question: table_name, cell: cell)
          adults = universe.members.
            where(inclusion_clause).
            where( # with Income and Sources at start and at <suffix>
              a_t[:income_from_any_source_at_start].eq(1).
              and(a_t["income_from_any_source_at_#{suffix}".to_sym].eq(1)).
              and(a_t[:income_total_at_start].gt(0)).
              and(a_t["income_total_at_#{suffix}".to_sym].gt(0)),
            )
          (ids, amounts) = ids_and_amounts(
            adults,
            column: column[:column],
            income_category: income_category,
            suffix: suffix,
          )

          members = adults.where(id: ids)
          answer.add_members(members)

          if column[:column] == 'J'
            percent = 0
            percent = (members.count.to_f / adults.count).round(4) if ids.any?
            answer.update(summary: percent)
            next
          end

          case calculation
          when :count
            answer.update(summary: members.count)
          when :average
            average = 0
            average = (amounts.sum.to_f / ids.count).round(2) if ids.any?
            answer.update(summary: average)
          end
        end
      end
    end

    private def q19a_stayers
      table_name = 'Q19a1'
      metadata = {
        header_row: ['Income Change by Income Category (Universe: Adult Stayers with Income Information at Start and Annual Assessment)'] + income_stati_stayers.keys,
        row_labels: income_counts.keys,
        first_column: 'B',
        last_column: 'J',
        first_row: 2,
        last_row: 7,
      }
      @report.answer(question: table_name).update(metadata: metadata)
      suffix = :annual_assessment
      # All adult stayers where the head of household has been in the project 365 days or more
      inclusion_clause = a_t[:head_of_household_id].in(hoh_lts_stayer_ids).
        and(adult_clause.or(a_t[:head_of_household].eq(true))).
        and(stayers_clause)

      q19a(
        table_name,
        metadata,
        income_status_method: :income_stati_stayers,
        suffix: suffix,
        inclusion_clause: inclusion_clause,
      )
    end

    private def q19a_leavers
      table_name = 'Q19a2'
      metadata = {
        header_row: ['Income Change by Income Category (Universe: Adult Leavers with Income Information at Start and Exit)'] + income_stati_leavers.keys,
        row_labels: income_counts.keys,
        first_column: 'B',
        last_column: 'J',
        first_row: 2,
        last_row: 7,
      }
      @report.answer(question: table_name).update(metadata: metadata)
      suffix = :exit
      #  All adult leavers
      inclusion_clause = adult_clause.and(leavers_clause)

      q19a(
        table_name,
        metadata,
        income_status_method: :income_stati_stayers,
        suffix: suffix,
        inclusion_clause: inclusion_clause,
      )
    end

    private def ids_and_amounts(adults, column:, income_category:, suffix:)
      ids = Set.new
      amounts = Set.new
      adults.preload(:universe_membership).find_each do |member|
        apr_client = member.universe_membership
        income_difference = income_change(
          apr_client,
          category: income_category,
          initial: :start,
          subsequent: suffix,
        )
        case column
        when 'B'
          if income_for_category?(
            apr_client,
            category: income_category,
            suffix: :start,
          ) && ! income_for_category?(
            apr_client,
            category: income_category,
            suffix: suffix,
          )
            ids << member.id
            amounts << income_difference
          end
        when 'C'
          if income_for_category?(apr_client, category: income_category, suffix: :start) &&
          income_for_category?(apr_client, category: income_category, suffix: suffix) &&
          income_difference&.negative?
            ids << member.id
            amounts << income_difference
          end
        when 'D'
          ids << member.id if income_for_category?(
            apr_client,
            category: income_category,
            suffix: :start,
          ) && income_for_category?(
            apr_client,
            category: income_category,
            suffix: suffix,
          ) && income_difference&.zero?
        when 'E'
          if income_for_category?(
            apr_client,
            category: income_category,
            suffix: :start,
          ) && income_for_category?(
            apr_client,
            category: income_category,
            suffix: suffix,
          ) && income_difference&.positive?
            ids << member.id
            amounts << income_difference
          end
        when 'F'
          if ! income_for_category?(
            apr_client,
            category: income_category,
            suffix: :start,
          ) && income_for_category?(
            apr_client,
            category: income_category,
            suffix: suffix,
          )
            ids << member.id
            amounts << income_difference
          end
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
          if income_for_category?(
            apr_client,
            category: income_category,
            suffix: :start,
          ) && income_for_category?(
            apr_client,
            category: income_category,
            suffix: suffix,
          ) && income_difference&.positive?
            ids << member.id
            amounts << income_difference
          end
          # Include if the client gained income (same as F)
          if ! income_for_category?(
            apr_client,
            category: income_category,
            suffix: :start,
          ) && income_for_category?(
            apr_client,
            category: income_category,
            suffix: suffix,
          )
            ids << member.id
            amounts << income_difference
          end
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
          ) && income_difference&.positive?
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
      [ids, amounts]
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
          calculation: :average,
        },
        'Number of Adults with Other Income' => {
          category: :other,
          calculation: :count,
        },
        'Average Change in Other Income' => {
          category: :other,
          calculation: :average,
        },
        'Number of Adults with Any Income (i.e., Total Income)' => {
          category: :total,
          calculation: :count,
        },
        'Average Change in Overall Income' => {
          category: :total,
          calculation: :average,
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
          head_of_household: last_service_history_enrollment[:head_of_household],
          head_of_household_id: last_service_history_enrollment.head_of_household_id,
          length_of_stay: stay_length(last_service_history_enrollment),
          annual_assessment_expected: annual_assessment_expected?(last_service_history_enrollment),
          income_from_any_source_at_start: income_at_start&.IncomeFromAnySource,
          income_from_any_source_at_annual_assessment: income_at_annual_assessment&.IncomeFromAnySource,
          income_from_any_source_at_exit: income_at_exit&.IncomeFromAnySource,
          income_total_at_start: income_at_start&.hud_total_monthly_income&.to_i,
          income_total_at_annual_assessment: income_at_annual_assessment&.hud_total_monthly_income&.to_i,
          income_total_at_exit: income_at_exit&.hud_total_monthly_income&.to_i,
          income_sources_at_start: income_sources(income_at_start),
          income_sources_at_annual_assessment: income_sources(income_at_annual_assessment),
          income_sources_at_exit: income_sources(income_at_exit),
        )
      end
    end
  end
end
