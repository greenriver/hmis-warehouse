###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2021
  class QuestionNineteen < Base
    QUESTION_NUMBER = 'Question 19'.freeze

    def self.table_descriptions
      {
        'Question 19' => 'Cash Income – Changes over Time',
        'Q19a1' => 'Client Cash Income Change - Income Source - by Start and Latest Status',
        'Q19a2' => 'Client Cash Income Change - Income Source - by Start and Exit',
        'Q19b' => 'Disabling Conditions and Income for Adults at Exit',
      }.freeze
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
            where(inclusion_clause)

          case column[:amount_at_start]
          when :positive
            adults = adults.where(a_t[:income_total_at_start].gt(0))
          when :zero
            adults = adults.where(a_t[:income_total_at_start].eq(0))
          end

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
            percent = (members.count.to_f / adults.count) if ids.any?
            answer.update(summary: percentage(percent))
            next
          end

          case calculation
          when :count
            answer.update(summary: members.count)
          when :average
            average = 0
            average = (amounts.sum.to_f / ids.count) if ids.any?
            answer.update(summary: money(average))
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
        and(adult_clause).
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
        income_status_method: :income_stati_leavers,
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

          answer.update(summary: 0) and next if members.count.zero?

          if income_clause.is_a?(Hash)
            members = members.where.contains(income_clause)
          else
            # The final question doesn't require accessing the jsonb column
            members = members.where(income_clause)
          end
          if disabilities_clause.is_a?(Hash)
            value = percentage(0)
            disabled_count = members.where(disabilities_clause[:household]).
              where(a_t[:disabling_condition].eq(1)).count
            total_count = members.where(disabilities_clause[:household]).count
            value = percentage(disabled_count.to_f / total_count) if total_count.positive?
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
        'Adults with Income Information at Start and Annual Assessment/Exit',
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
        next if income_difference.blank? # if income in either initial or subsequent is blank, skip this client

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
        'Had Income Category at Start and Did Not Have It at Annual Assessment' => { column: 'B', amount_at_start: :positive },
        'Retained Income Category But Had Less $ at Annual Assessment Than at Start' => { column: 'C', amount_at_start: :positive },
        'Retained Income Category and Same $ at Annual Assessment as at Start' => { column: 'D', amount_at_start: :positive },
        'Retained Income Category and Increased $ at Annual Assessment' => { column: 'E', amount_at_start: :positive },
        'Did Not Have the Income Category at Start and Gained the Income Category at Annual Assessment' => { column: 'F', amount_at_start: :zero },
        'Did Not Have the Income Category at Start or at Annual Assessment' => { column: 'G', amount_at_start: :zero },
        'Total Adults (including those with No Income)' => { column: 'H', amount_at_start: :any },
        'Performance Measure: Adults who Gained or Increased Income from Start to Annual Assessment, Average Gain' => { column: 'I', amount_at_start: :any },
        'Performance measure: Percent of persons who accomplishe d this measure' => { column: 'J', amount_at_start: :any },
      }
    end

    private def income_stati_leavers
      {
        'Had Income Category at Start and Did Not Have It at Exit' => { column: 'B', amount_at_start: :positive },
        'Retained Income Category But Had Less $ at Exit Than at Start' => { column: 'C', amount_at_start: :positive },
        'Retained Income Category and Same $ at Exit as at Start' => { column: 'D', amount_at_start: :positive },
        'Retained Income Category and Increased $ at Exit' => { column: 'E', amount_at_start: :positive },
        'Did Not Have the Income Category at Start and Gained the Income Category at Exit' => { column: 'F', amount_at_start: :zero },
        'Did Not Have the Income Category at Start or at Exit' => { column: 'G', amount_at_start: :zero },
        'Total Adults (including those with No Income)' => { column: 'H', amount_at_start: :any },
        'Performance Measure: Adults who Gained or Increased Income from Start to Exit, Average Gain' => { column: 'I', amount_at_start: :any },
        'Performance measure: Percent of persons who accomplished this measure' => { column: 'J', amount_at_start: :any },
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
  end
end
