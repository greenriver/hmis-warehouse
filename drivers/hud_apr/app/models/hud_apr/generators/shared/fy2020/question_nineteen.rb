###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionNineteen < Base
    QUESTION_NUMBER = 'Question 19'.freeze
    QUESTION_TABLE_NUMBERS = ['Q19a1', 'Q19a2', 'Q19b'].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    private def q19a(table_name, metadata, income_status_method:, suffix:, inclusion_clause:)
      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      send(income_status_method).values.each_with_index do |column, col_index|
        income_counts.values.each_with_index do |income_options, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank_q19a.include?(cell)

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

    private def q19b_disabling_conditions
      table_name = 'Q19b'
      metadata = {
        header_row: [' '] + adult_disabilities.keys,
        row_labels: q19b_income_sources.keys,
        first_column: 'B',
        last_column: 'M',
        first_row: 2,
        last_row: 14,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      adult_disabilities.values.each_with_index do |disabilities_clause, col_index|
        q19b_income_sources.values.each_with_index do |income_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank_q19b.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)
          members = universe.members.
            # Only relevant to adult leavers with answers for income at exit and disability
            where(adult_clause).
            where(leavers_clause).
            where(a_t[:disabling_condition].in([0, 1])).
            where(a_t[:income_from_any_source_at_exit].in([0, 1]))
          if income_clause.is_a?(Hash)
            members = members.where.contains(income_clause)
          else
            # The final question doesn't require accessing the jsonb column
            members = members.where(income_clause)
          end
          value = 0
          if disabilities_clause.is_a?(Hash)
            disabled_count = members.where(disabilities_clause[:household]).
              where(a_t[:disabling_condition].eq(1)).count
            total_count = members.where(disabilities_clause[:household]).count
            value = (disabled_count.to_f / total_count).round(4) if total_count.positive?
          else
            members = members.where(disabilities_clause)
            value = members.count
          end

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def adult_disabilities
      {
        'AO: Adult with Disabling Condition' => a_t[:disabling_condition].eq(1).
          and(a_t[:household_type].eq(:adults_only)),
        'AO: Adult without Disabling Condition' => a_t[:disabling_condition].eq(0).
          and(a_t[:household_type].eq(:adults_only)),
        'AO: Total Adults' => a_t[:household_type].eq(:adults_only),
        'AO: % with Disabling Condition by Source' => {
          calculation: :percent,
          household: a_t[:household_type].eq(:adults_only),
        },
        'AC: Adult with Disabling Condition' => a_t[:disabling_condition].eq(1).
          and(a_t[:household_type].eq(:adults_and_children)),
        'AC: Adult without Disabling Condition' => a_t[:disabling_condition].eq(0).
          and(a_t[:household_type].eq(:adults_and_children)),
        'AC: Total Adults' => a_t[:household_type].eq(:adults_and_children),
        'AC: % with Disabling Condition by Source' => {
          calculation: :percent,
          household: a_t[:household_type].eq(:adults_and_children),
        },
        'UK: Adult with Disabling Condition' => a_t[:disabling_condition].eq(1).
          and(a_t[:household_type].eq(:unknown)),
        'UK: Adult without Disabling Condition' => a_t[:disabling_condition].eq(0).
          and(a_t[:household_type].eq(:unknown)),
        'UK: Total Adults' => a_t[:household_type].eq(:unknown),
        'UK: % with Disabling Condition by Source' => {
          calculation: :percent,
          household: a_t[:household_type].eq(:unknown),
        },
      }
    end

    private def q19b_income_sources
      income_types(:exit).except(
        'Unemployment Insurance',
        'VA Non-Service Connected Disability Pension',
        'General Assistance (GA)',
        'Alimony and other spousal support',
      ).merge(
        {
          'No Sources' => a_t[:income_from_any_source_at_exit].eq(0),
          'Unduplicated Total Adults' => Arel.sql('1=1'),
        },
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

    private def intentionally_blank_q19a
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

    private def intentionally_blank_q19b
      [
        'E14',
        'I14',
        'M14',
      ].freeze
    end

    private def universe
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
          household_type: @household_types[last_service_history_enrollment.household_id],
          disabling_condition: enrollment.DisablingCondition,
        )
      end
    end
  end
end
