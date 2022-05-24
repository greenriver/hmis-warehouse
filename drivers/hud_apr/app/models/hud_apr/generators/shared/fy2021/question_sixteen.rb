###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2021
  class QuestionSixteen < Base
    QUESTION_NUMBER = 'Question 16'.freeze

    def self.table_descriptions
      {
        'Question 16' => 'Cash Income - Ranges',
      }.freeze
    end

    private def q16_cash_ranges
      table_name = 'Q16'
      metadata = {
        header_row: [' '] + income_stages.keys,
        row_labels: income_headers,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 14,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      income_stages.values.each_with_index do |suffix, col_index|
        income_levels(suffix).values.each_with_index do |income_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)
          members = universe.members.
            where(adult_clause).
            where(income_clause)

          case suffix
          when :start
            # Nothing
          when :annual_assessment
            members = members.where(stayers_clause)
            members = members.where(a_t[:annual_assessment_expected].eq(true)) unless ignore_annual_assessment_filter.include?(cell)
          when :exit
            members = members.where(leavers_clause)
          end

          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    private def income_headers
      income_levels('').keys
    end

    private def income_stages
      {
        'Income at Start' => :start,
        'Income at Latest Annual Assessment for Stayers' => :annual_assessment,
        'Income at Exit for Leavers' => :exit,
      }
    end

    private def income_levels(suffix)
      {
        'No Income' => a_t["income_total_at_#{suffix}".to_sym].eq(0),
        '$1 - $150' => a_t["income_total_at_#{suffix}".to_sym].between(1..150),
        '$151 - $250' => a_t["income_total_at_#{suffix}".to_sym].between(151..250),
        '$251 - $500' => a_t["income_total_at_#{suffix}".to_sym].between(251..500),
        '$501 - $1,000' => a_t["income_total_at_#{suffix}".to_sym].between(501..1_000),
        '$1,001 - $1,500' => a_t["income_total_at_#{suffix}".to_sym].between(1_001..1_500),
        '$1,501 - $2,000' => a_t["income_total_at_#{suffix}".to_sym].between(1_501..2_000),
        '$2,001+' => a_t["income_total_at_#{suffix}".to_sym].gt(2_000),
        'Client Doesn\'t Know/Client Refused' => a_t["income_total_at_#{suffix}".to_sym].eq(nil).
          and(a_t["income_from_any_source_at_#{suffix}".to_sym].in([8, 9])),
        'Data Not Collected' => a_t["income_total_at_#{suffix}".to_sym].eq(nil).
          and(
            a_t["income_from_any_source_at_#{suffix}".to_sym].eq(99).
            or(a_t["income_from_any_source_at_#{suffix}".to_sym].eq(nil)),
          ),
        'Number of adult stayers not yet required to have an annual assessment' => adult_clause.
          and(stayers_clause).
          and(a_t[:annual_assessment_expected].eq(false)),
        'Number of adult stayers without required annual assessment' => adult_clause.
          and(stayers_clause).
          and(a_t[:annual_assessment_expected].eq(true)).
          and(a_t[:income_from_any_source_at_annual_assessment].eq(nil)),
        'Total Adults' => Arel.sql('1=1'),
      }
    end

    private def intentionally_blank
      [
        'B12',
        'B13',
        'D12',
        'D13',
      ].freeze
    end

    private def ignore_annual_assessment_filter
      [
        'C12',
        'C13',
        'C14', # must match Q5-B9 (adult stayers)
      ].freeze
    end
  end
end
