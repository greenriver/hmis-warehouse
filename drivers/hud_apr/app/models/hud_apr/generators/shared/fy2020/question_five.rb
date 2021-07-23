###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionFive < Base
    QUESTION_NUMBER = 'Question 5'.freeze

    TABLE_HEADER = [].freeze
    ROW_LABELS = [
      'Total number of persons served',
      'Number of adults (age 18 or over)',
      'Number of children (under age 18)',
      'Number of persons with unknown age',
      'Number of leavers',
      'Number of adult leavers',
      'Number of adult and head of household leavers',
      'Number of stayers',
      'Number of adult stayers',
      'Number of veterans',
      'Number of chronically homeless persons',
      'Number of youth under age 25',
      'Number of parenting youth under age 25 with children',
      'Number of adult heads of household',
      'Number of child and unknown-age heads of household',
      'Heads of households and adult stayers in the project 365 days or more',
    ].freeze

    private def q5_validations
      table_name = 'Q5a'
      metadata = {
        header_row: TABLE_HEADER,
        row_labels: ROW_LABELS,
        first_column: 'B',
        last_column: 'B',
        first_row: 1,
        last_row: 16,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      # Total clients
      answer = @report.answer(question: table_name, cell: 'B1')
      members = universe.universe_members
      answer.add_members(members)
      answer.update(summary: members.count)

      [
        # Number of adults
        {
          cell: 'B2',
          clause: adult_clause,
        },
        # Number of children
        {
          cell: 'B3',
          clause: child_clause,
        },
        # Number of unknown ages
        {
          cell: 'B4',
          clause: a_t[:age].eq(nil).or(a_t[:age].lt(0)),
        },
        # Number of leavers
        {
          cell: 'B5',
          clause: leavers_clause,
        },
        # Number of adult leavers
        {
          cell: 'B6',
          clause: leavers_clause.and(adult_clause),
        },
        # Number of adult and HoH leavers
        {
          cell: 'B7',
          clause: leavers_clause.
            and(adult_clause.
              or(a_t[:head_of_household].eq(true))),
        },
        # Number of stayers
        {
          cell: 'B8',
          clause: stayers_clause,
        },
        # Number of adult stayers
        # must match Q16-C14
        {
          cell: 'B9',
          clause: stayers_clause.
            and(adult_clause),
        },
        # Number of veterans
        {
          cell: 'B10',
          clause: veteran_clause,
        },
        # Number of chronically homeless
        {
          cell: 'B11',
          clause: a_t[:chronically_homeless].eq(true),
        },
        # Number of youth under 25
        {
          cell: 'B12',
          clause: a_t[:age].lt(25).
            and(a_t[:age].gteq(12)).
            and(a_t[:other_clients_over_25].eq(false)),
        },
        # Number of parenting youth under 25 with children
        {
          cell: 'B13',
          clause: a_t[:age].lt(25).
            and(a_t[:age].gteq(12)).
            and(a_t[:parenting_youth].eq(true)),
        },
        # Number of adult HoH
        {
          cell: 'B14',
          clause: adult_clause.
            and(a_t[:head_of_household].eq(true)),
        },
        # Number of child and unknown age HoH
        {
          cell: 'B15',
          clause: a_t[:age].lt(18).
            or(a_t[:age].eq(nil)).
            and(a_t[:head_of_household].eq(true)),
        },
      ].each do |cell|
        answer = @report.answer(question: table_name, cell: cell[:cell])
        members = universe.members.where(cell[:clause])
        answer.add_members(members)
        answer.update(summary: members.count)
      end

      # HoH and adult stayers in project 365 days or more
      # "...any adult stayer present when the head of household’s stay is 365 days or more,
      # even if that adult has not been in the household that long"
      answer = @report.answer(question: table_name, cell: 'B16')
      members = universe.members.where(
        a_t[:head_of_household_id].in(hoh_lts_stayer_ids).
        and(adult_clause.or(a_t[:head_of_household].eq(true))),
      )
      answer.add_members(members)
      answer.update(summary: members.count)
    end
  end
end
