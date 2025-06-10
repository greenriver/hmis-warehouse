###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Shared::Fy2024
  class QuestionSixteen < Base
    QUESTION_NUMBER = 'Question 16'

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
      not_collected = a_t["income_from_any_source_at_#{suffix}".to_sym].eq(nil).
        or(a_t["income_from_any_source_at_#{suffix}".to_sym].eq(99)).
        or(
          a_t["income_total_at_#{suffix}"].eq(nil).
          and(
            # Responses of 8 & 9 are expected to have total income nil.
            # These are filtered out to prevent duplicates. They are captured in a different row.
            a_t["income_from_any_source_at_#{suffix}"].not_in([8, 9]).or(a_t["income_from_any_source_at_#{suffix}"].eq(nil)),
          ),
        )

      # for annual assessments, only count as missing if the annual assessment actually happened
      # Following DataLab APR sample code for which values go in which categories
      # https://github.com/HUD-Data-Lab/DataLab/blob/bed28f9bde1bff1efd53a7a166d141f40526cdf8/datalab_functions.R#L224-L231
      # calculated_total_income == 0 ~ "No Income",
      # calculated_total_income <= 150 ~ "$1 - $150",
      # calculated_total_income <= 250 ~ "$151 - $250",
      # calculated_total_income <= 500 ~ "$251 - $500",
      # calculated_total_income <= 1000 ~ "$501 - $1,000",
      # calculated_total_income <= 1500 ~ "$1,001 - $1,500",
      # calculated_total_income <= 2000 ~ "$1,501 - $2,000",
      # TRUE ~ "$2,001+"))
      not_collected = not_collected.and(a_t[:annual_assessment_in_window].eq(true)) if suffix == :annual_assessment
      {
        'No Income' => a_t["income_total_at_#{suffix}".to_sym].eq(0).and(a_t["income_from_any_source_at_#{suffix}".to_sym].in([1, 0])),
        '$1 - $150' => a_t["income_total_at_#{suffix}".to_sym].gt(0).and(a_t["income_total_at_#{suffix}".to_sym].lteq(150)), # account for income of $0.01
        '$151 - $250' => a_t["income_total_at_#{suffix}".to_sym].gt(150).and(a_t["income_total_at_#{suffix}".to_sym].lteq(250)),
        '$251 - $500' => a_t["income_total_at_#{suffix}".to_sym].gt(250).and(a_t["income_total_at_#{suffix}".to_sym].lteq(500)),
        '$501 - $1,000' => a_t["income_total_at_#{suffix}".to_sym].gt(500).and(a_t["income_total_at_#{suffix}".to_sym].lteq(1_000)),
        '$1,001 - $1,500' => a_t["income_total_at_#{suffix}".to_sym].gt(1_000).and(a_t["income_total_at_#{suffix}".to_sym].lteq(1_500)),
        '$1,501 - $2,000' => a_t["income_total_at_#{suffix}".to_sym].gt(1_500).and(a_t["income_total_at_#{suffix}".to_sym].lteq(2_000)),
        '$2,001+' => a_t["income_total_at_#{suffix}".to_sym].gt(2_000),
        label_for(:dkptr) => a_t["income_total_at_#{suffix}".to_sym].eq(nil).
          and(a_t["income_from_any_source_at_#{suffix}".to_sym].in([8, 9])),
        label_for(:data_not_collected) => not_collected,
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
