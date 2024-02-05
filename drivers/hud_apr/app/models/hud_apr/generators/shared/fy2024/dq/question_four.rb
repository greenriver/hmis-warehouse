###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2024::Dq::QuestionFour
  extend ActiveSupport::Concern

  included do
    private def generate_q4(table_name) # rubocop:disable Metrics/AbcSize
      metadata = {
        header_row: [
          'Data Element',
          label_for(:dkptr),
          label_for(:info_missing),
          'Data Issues',
          'Total',
          '% of Issue Rate',
        ],
        row_labels: [
          'Destination (3.12)',
          'Income and Sources (4.02) at Start',
          'Income and Sources (4.02) at Annual Assessment',
          'Income and Sources (4.02) at Exit',
        ],
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 5,
      }
      @report.answer(question: table_name).update(metadata: metadata)
      universe_members = universe.members.where(engaged_clause)

      # destinations
      leavers = universe_members.where(leavers_clause)

      answer = @report.answer(question: table_name, cell: 'B2')
      members = leavers.where(a_t[:destination].in([8, 9]))
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C2')
      members = leavers.where(
        a_t[:destination].in([30, 99]).
          or(a_t[:destination].eq(nil)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # D2 does not have programming specs
      #
      answer = @report.answer(question: table_name, cell: 'E2')
      members = leavers.where(
        a_t[:destination].in([8, 9, 30, 99]).
          or(a_t[:destination].eq(nil)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'F2')
      answer.update(summary: percentage(members.count / leavers.count.to_f))

      # incomes
      adults_and_hohs = universe_members.where(adult_or_hoh_clause)
      # income at start
      answer = @report.answer(question: table_name, cell: 'B3')
      members = adults_and_hohs.where(a_t[:income_from_any_source_at_start].in([8, 9]))
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C3')
      members = adults_and_hohs.where(
        a_t[:income_date_at_start].eq(nil).
          or(a_t[:income_date_at_start].not_eq(a_t[:first_date_in_program])).
          or(a_t[:income_from_any_source_at_start].in([99])).
          or(a_t[:income_from_any_source_at_start].eq(nil)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'D3')
      members = adults_and_hohs.where(
        a_t[:income_from_any_source_at_start].eq(0). # any says no, but there is a source
          and(income_jsonb_clause(1, a_t[:income_sources_at_start].to_sql)).
        or(
          a_t[:income_from_any_source_at_start].eq(1). # any says yes, but no sources
            and(income_jsonb_clause(1, a_t[:income_sources_at_start].to_sql, negation: true)),
        ),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'E3')
      members = adults_and_hohs.where(
        a_t[:income_date_at_start].eq(nil).
          or(a_t[:income_date_at_start].not_eq(a_t[:first_date_in_program])).
          or(a_t[:income_from_any_source_at_start].in([8, 9, 99])).
          or(a_t[:income_from_any_source_at_start].eq(nil)).
          or(a_t[:income_from_any_source_at_start].eq(0). # any says no, but there is a source
            and(income_jsonb_clause(1, a_t[:income_sources_at_start].to_sql))).
          or(a_t[:income_from_any_source_at_start].eq(1). # any says yes, but no sources
            and(income_jsonb_clause(1, a_t[:income_sources_at_start].to_sql, negation: true))),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'F3')
      answer.update(summary: percentage(members.count / adults_and_hohs.count.to_f))

      # income at anniversary
      stayers_with_anniversary = adults_and_hohs.where(
        a_t[:annual_assessment_expected].eq(true).
          and(stayers_clause),
      )

      answer = @report.answer(question: table_name, cell: 'B4')
      members = stayers_with_anniversary.where(a_t[:income_from_any_source_at_annual_assessment].in([8, 9]))
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C4')
      members = stayers_with_anniversary.where(
        a_t[:income_date_at_annual_assessment].eq(nil).
          or(a_t[:annual_assessment_in_window].eq(false)).
          or(a_t[:income_from_any_source_at_annual_assessment].in([99])).
          or(a_t[:income_from_any_source_at_annual_assessment].eq(nil)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'D4')
      members = stayers_with_anniversary.where(
        a_t[:income_from_any_source_at_annual_assessment].eq(0).
          and(income_jsonb_clause(1, a_t[:income_sources_at_annual_assessment].to_sql)).
        or(
          a_t[:income_from_any_source_at_annual_assessment].eq(1).
            and(income_jsonb_clause(1, a_t[:income_sources_at_annual_assessment].to_sql, negation: true)),
        ),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'E4')
      members = stayers_with_anniversary.where(
        a_t[:income_date_at_annual_assessment].eq(nil).
          or(a_t[:annual_assessment_in_window].eq(false)).
          or(a_t[:income_from_any_source_at_annual_assessment].in([8, 9, 99])).
          or(a_t[:income_from_any_source_at_annual_assessment].eq(nil)).
          or(a_t[:income_from_any_source_at_annual_assessment].eq(0).
            and(income_jsonb_clause(1, a_t[:income_sources_at_annual_assessment].to_sql))).
          or(a_t[:income_from_any_source_at_annual_assessment].eq(1).
            and(income_jsonb_clause(1, a_t[:income_sources_at_annual_assessment].to_sql, negation: true))),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'F4')
      answer.update(summary: percentage(members.count / stayers_with_anniversary.count.to_f))

      # income at exit
      leavers = adults_and_hohs.where(a_t[:last_date_in_program].lteq(@report.end_date))

      answer = @report.answer(question: table_name, cell: 'B5')
      members = leavers.where(a_t[:income_from_any_source_at_exit].in([8, 9, 99]))
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C5')
      members = leavers.where(
        a_t[:income_date_at_exit].eq(nil).
          or(a_t[:income_date_at_exit].not_eq(a_t[:last_date_in_program])).
          or(a_t[:income_from_any_source_at_exit].in([99])).
          or(a_t[:income_from_any_source_at_exit].eq(nil)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'D5')
      members = leavers.where(
        a_t[:income_from_any_source_at_exit].eq(0).
          and(income_jsonb_clause(1, a_t[:income_sources_at_exit].to_sql)).
        or(
          a_t[:income_from_any_source_at_exit].eq(1).
            and(income_jsonb_clause(1, a_t[:income_sources_at_exit].to_sql, negation: true)),
        ),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'E5')
      members = leavers.where(
        a_t[:income_date_at_exit].eq(nil).
          or(a_t[:income_date_at_exit].not_eq(a_t[:last_date_in_program])).
          or(a_t[:income_from_any_source_at_exit].in([8, 9, 99])).
          or(a_t[:income_from_any_source_at_exit].eq(nil)).
          or(a_t[:income_from_any_source_at_exit].eq(0).
            and(income_jsonb_clause(1, a_t[:income_sources_at_exit].to_sql))).
          or(a_t[:income_from_any_source_at_exit].eq(1).
            and(income_jsonb_clause(1, a_t[:income_sources_at_exit].to_sql, negation: true))),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'F5')
      answer.update(summary: percentage(members.count / leavers.count.to_f))
    end
  end
end
