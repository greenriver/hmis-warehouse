###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudDataQualityReport::Generators::Fy2021
  class QuestionFour < Base
    include ArelHelper

    QUESTION_NUMBER = 'Question 4'.freeze
    QUESTION_TABLE_NUMBER = 'Q4'.freeze
    QUESTION_TABLE_NUMBERS = [QUESTION_TABLE_NUMBER].freeze

    def self.table_descriptions
      {
        'Question 4' => 'Income and Housing Data Quality',
      }.freeze
    end

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question! # rubocop:disable Metrics/AbcSize
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])
      table_name = QUESTION_TABLE_NUMBER

      metadata = {
        header_row: [
          'Data Element',
          'Error Count',
          '% of Error Rate',
        ],
        row_labels: [
          'Destination (3.12)',
          'Income and Sources (4.02) at Start',
          'Income and Sources (4.02) at Annual Assessment',
          'Income and Sources (4.02) at Exit',
        ],
        first_column: 'B',
        last_column: 'C',
        first_row: 2,
        last_row: 5,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      # destinations
      leavers = universe.members.where(leavers_clause)

      answer = @report.answer(question: table_name, cell: 'B2')
      members = leavers.where(
        a_t[:destination].in([8, 9, 30]).
          or(a_t[:destination].eq(nil)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C2')
      answer.update(summary: percentage(members.count / leavers.count.to_f))

      # incomes
      adults_and_hohs = universe.members.where(adult_or_hoh_clause)
      # income at start
      answer = @report.answer(question: table_name, cell: 'B3')
      members = adults_and_hohs.where(
        a_t[:income_date_at_start].eq(nil).
          or(a_t[:income_date_at_start].not_eq(a_t[:first_date_in_program])).
          or(a_t[:income_from_any_source_at_start].in([8, 9])).
          or(a_t[:income_from_any_source_at_start].eq(nil)).
          or(a_t[:income_from_any_source_at_start].eq(0).
            and(income_jsonb_clause(1, a_t[:income_sources_at_start].to_sql))).
          or(a_t[:income_from_any_source_at_start].eq(1).
            and(income_jsonb_clause(1, a_t[:income_sources_at_start].to_sql, negation: true))),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C3')
      answer.update(summary: percentage(members.count / adults_and_hohs.count.to_f))

      # income at anniversary
      stayers_with_anniversary = adults_and_hohs.where(
        a_t[:annual_assessment_expected].eq(true).
          and(stayers_clause),
      )

      answer = @report.answer(question: table_name, cell: 'B4')
      members = stayers_with_anniversary.where(
        a_t[:income_date_at_annual_assessment].eq(nil).
          or(a_t[:annual_assessment_in_window].eq(false)).
          or(a_t[:income_from_any_source_at_annual_assessment].in([8, 9])).
          or(a_t[:income_from_any_source_at_annual_assessment].eq(nil)).
          or(a_t[:income_from_any_source_at_annual_assessment].eq(0).
            and(income_jsonb_clause(1, a_t[:income_sources_at_annual_assessment].to_sql))).
          or(a_t[:income_from_any_source_at_annual_assessment].eq(1).
            and(income_jsonb_clause(1, a_t[:income_sources_at_annual_assessment].to_sql, negation: true))),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C4')
      answer.update(summary: percentage(members.count / stayers_with_anniversary.count.to_f))

      # income at exit
      leavers = adults_and_hohs.where(a_t[:last_date_in_program].lteq(@report.end_date))

      answer = @report.answer(question: table_name, cell: 'B5')
      members = leavers.where(
        a_t[:income_date_at_exit].eq(nil).
          or(a_t[:income_date_at_exit].not_eq(a_t[:last_date_in_program])).
          or(a_t[:income_from_any_source_at_exit].in([8, 9])).
          or(a_t[:income_from_any_source_at_exit].eq(nil)).
          or(a_t[:income_from_any_source_at_exit].eq(0).
            and(income_jsonb_clause(1, a_t[:income_sources_at_exit].to_sql))).
          or(a_t[:income_from_any_source_at_exit].eq(1).
            and(income_jsonb_clause(1, a_t[:income_sources_at_exit].to_sql, negation: true))),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C5')
      answer.update(summary: percentage(members.count / leavers.count.to_f))

      @report.complete(QUESTION_NUMBER)
    end
  end
end
