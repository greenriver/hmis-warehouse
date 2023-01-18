###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2023
  class QuestionFive < Base
    QUESTION_NUMBER = 'Question 5'.freeze

    TABLE_HEADER = [
      'Category',
      'Count of Clients for DQ',
      'Count of Clients',
    ].freeze
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

    private def intentionally_blank
      []
    end

    def self.table_descriptions
      {
        'Question 5' => 'Report Validations',
        'Q5a' => 'Report Validations Table',
      }.freeze
    end

    private def active_questions
      [
        # Number of adults
        {
          row: '3',
          clause: adult_clause,
        },
        # Number of children
        {
          row: '4',
          clause: child_clause,
        },
        # Number of unknown ages
        {
          row: '5',
          clause: a_t[:age].eq(nil).or(a_t[:age].lt(0)),
        },
        # Number of leavers
        {
          row: '6',
          clause: leavers_clause,
        },
        # Number of adult leavers
        {
          row: '7',
          clause: leavers_clause.and(adult_clause),
        },
        # Number of adult and HoH leavers
        {
          row: '8',
          clause: leavers_clause.
            and(adult_clause.
              or(a_t[:head_of_household].eq(true))),
        },
        # Number of stayers
        {
          row: '9',
          clause: stayers_clause,
        },
        # Number of adult stayers
        # must match Q16-C14
        {
          row: '10',
          clause: stayers_clause.
            and(adult_clause),
        },
        # Number of veterans
        {
          row: '11',
          clause: veteran_clause,
        },
        # Number of chronically homeless
        {
          row: '12',
          clause: a_t[:chronically_homeless].eq(true),
        },
        # Number of youth under 25
        {
          row: '13',
          clause: a_t[:age].lt(25).
            and(a_t[:age].gteq(12)).
            and(a_t[:other_clients_over_25].eq(false)),
        },
        # Number of parenting youth under 25 with children
        {
          row: '14',
          clause: a_t[:age].lt(25).
            and(a_t[:age].gteq(12)).
            and(a_t[:parenting_youth].eq(true)),
        },
        # Number of adult HoH
        {
          row: '15',
          clause: adult_clause.
            and(a_t[:head_of_household].eq(true)),
        },
        # Number of child and unknown age HoH
        {
          row: '16',
          clause: a_t[:age].lt(18).
            or(a_t[:age].eq(nil)).
            and(a_t[:head_of_household].eq(true)),
        },
        # HoH and adult stayers in project 365 days or more
        # "...any adult stayer present when the head of household’s stay is 365 days or more,
        # even if that adult has not been in the household that long"
        {
          row: '17',
          clause: a_t[:head_of_household_id].in(hoh_lts_stayer_ids).
            and(adult_clause.or(a_t[:head_of_household].eq(true))),
        },
      ]
    end

    private def q5_validations
      table_name = 'Q5a'
      metadata = {
        header_row: TABLE_HEADER,
        row_labels: ROW_LABELS,
        first_column: 'B',
        last_column: 'C',
        first_row: 2,
        last_row: 17,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      ['B', 'C'].each do |col|
        # Column B is limited to engaged clients for SO, column C is not
        inclusion_clause = if col == 'B'
          engaged_clause
        else
          Arel.sql('1=1')
        end
        # Total clients
        cell = "#{col}2"

        answer = @report.answer(question: table_name, cell: cell)

        members = universe.members.where(inclusion_clause)
        answer.add_members(members)
        answer.update(summary: members.count)

        active_questions.each do |data|
          cell = "#{col}#{data[:row]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)
          members = universe.members.where(inclusion_clause).where(data[:clause])
          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end
  end
end
