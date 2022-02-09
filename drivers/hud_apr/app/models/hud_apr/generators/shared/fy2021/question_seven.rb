###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2021
  class QuestionSeven < Base
    QUESTION_NUMBER = 'Question 7'.freeze

    def self.table_descriptions
      {
        'Question 7' => 'Persons Served',
        'Q7a' => 'Number of Persons Served',
        'Q7b' => 'Point-in-Time Count of Persons on the Last Wednesday',
      }.freeze
    end

    private def q7a_persons_served
      table_name = 'Q7a'
      metadata = {
        header_row: header_row,
        row_labels: [
          'Adults',
          'Children',
          'Client Doesn’t Know/ Client Refused',
          'Data Not Collected',
          'Total',
          'For PSH & RRH – the total persons served who moved into housing',
        ],
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 7,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      [
        # Number of adults
        {
          cell: 'B2',
          clause: adult_clause,
        },
        # Number of adults w/ no children
        {
          cell: 'C2',
          clause: adult_clause.
            and(a_t[:household_type].eq(:adults_only)),
        },
        # Number of adults w/ children
        {
          cell: 'D2',
          clause: adult_clause.
            and(a_t[:household_type].eq(:adults_and_children)),
        },
        # Number of adults in unknown household type
        {
          cell: 'F2',
          clause: adult_clause.
            and(a_t[:household_type].eq(:unknown)),
        },
        # Number of children
        {
          cell: 'B3',
          clause: child_clause,
        },
        # Number of children w/ adults
        {
          cell: 'D3',
          clause: child_clause.
            and(a_t[:household_type].eq(:adults_and_children)),
        },
        # Number of children w/ no adults
        {
          cell: 'E3',
          clause: child_clause.
            and(a_t[:household_type].eq(:children_only)),
        },
        # Number of children in unknown household type
        {
          cell: 'F3',
          clause: child_clause.
            and(a_t[:household_type].eq(:unknown)),
        },
        # Number of DK/R
        {
          cell: 'B4',
          clause: a_t[:dob_quality].in([8, 9]),
        },
        # Number of DK/R w/ no children
        {
          cell: 'C4',
          clause: a_t[:dob_quality].in([8, 9]).
            and(a_t[:household_type].eq(:adults_only)),
        },
        # Number of DK/R w/ children
        {
          cell: 'D4',
          clause: a_t[:dob_quality].in([8, 9]).
            and(a_t[:household_type].eq(:adults_and_children)),
        },
        # Number of DK/R w/ no adults
        {
          cell: 'E4',
          clause: a_t[:dob_quality].in([8, 9]).
            and(a_t[:household_type].eq(:children_only)),
        },
        # Number of DK/R in unknown household type
        {
          cell: 'F4',
          clause: a_t[:dob_quality].in([8, 9]).
            and(a_t[:household_type].eq(:unknown)),
        },
        # Number of NC
        {
          cell: 'B5',
          clause: a_t[:dob].eq(nil).and(a_t[:dob_quality].not_in([8, 9])),
        },
        # Number of NC w/ no children
        {
          cell: 'C5',
          clause: a_t[:dob].eq(nil).and(a_t[:dob_quality].not_in([8, 9])).
            and(a_t[:household_type].eq(:adults_only)),
        },
        # Number of NC w/ children
        {
          cell: 'D5',
          clause: a_t[:dob].eq(nil).and(a_t[:dob_quality].not_in([8, 9])).
            and(a_t[:household_type].eq(:adults_and_children)),
        },
        # Number of NC w/ no adults
        {
          cell: 'E5',
          clause: a_t[:dob].eq(nil).and(a_t[:dob_quality].not_in([8, 9])).
            and(a_t[:household_type].eq(:children_only)),
        },
        # Number of NC in unknown household type
        {
          cell: 'F5',
          clause: a_t[:dob].eq(nil).and(a_t[:dob_quality].not_in([8, 9])).
            and(a_t[:household_type].eq(:unknown)),
        },
        # Total
        {
          cell: 'B6',
          clause: Arel.sql('1=1'),
        },
        # Total w/ no children
        {
          cell: 'C6',
          clause: a_t[:household_type].eq(:adults_only),
        },
        # Total w/ children
        {
          cell: 'D6',
          clause: a_t[:household_type].eq(:adults_and_children),
        },
        # Total w/ no adults
        {
          cell: 'E6',
          clause: a_t[:household_type].eq(:children_only),
        },
        # Total in unknown household type
        {
          cell: 'F6',
          clause: a_t[:household_type].eq(:unknown),
        },
      ].each do |cell|
        answer = @report.answer(question: table_name, cell: cell[:cell])
        members = universe.members.where(cell[:clause])
        answer.add_members(members)
        answer.update(summary: members.count)
      end

      ps_rrh_w_move_in = universe.members.where(
        a_t[:project_type].in([3, 13]).
          and(a_t[:move_in_date].not_eq(nil)),
      )
      row_seven_cells.each do |cell|
        answer = @report.answer(question: table_name, cell: cell[:cell])
        members = ps_rrh_w_move_in.where(cell[:clause])
        answer.add_members(members)
        answer.update(summary: members.count)
      end
    end

    private def row_seven_cells
      [
        # PSH/RRH w/ move in date
        {
          cell: 'B7',
          clause: Arel.sql('1=1'),
        },
        # w/ no children
        {
          cell: 'C7',
          clause: a_t[:household_type].eq(:adults_only),
        },
        # w/ children
        {
          cell: 'D7',
          clause: a_t[:household_type].eq(:adults_and_children),
        },
        # w/ no adults
        {
          cell: 'E7',
          clause: a_t[:household_type].eq(:children_only),
        },
        # in unknown household type
        {
          cell: 'F7',
          clause: a_t[:household_type].eq(:unknown),
        },
      ]
    end

    protected def header_row
      [
        ' ',
        'Total',
        'Without Children',
        'With Children and Adults',
        'With Only Children',
        'Unknown Household Type',
      ].freeze
    end

    private def q7b_pit_count
      table_name = 'Q7b'
      metadata = {
        header_row: header_row,
        row_labels: [
          'January',
          'April',
          'July',
          'October',
        ],
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 5,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      pit_row(month: 1, table_name: table_name, row: 2)
      pit_row(month: 4, table_name: table_name, row: 3)
      pit_row(month: 7, table_name: table_name, row: 4)
      pit_row(month: 10, table_name: table_name, row: 5)
    end

    private def pit_row(month:, table_name:, row:)
      row_universe = pit_universe(month: month)

      # Total
      answer = @report.answer(question: table_name, cell: 'B' + row.to_s)
      members = row_universe
      answer.add_members(members)
      answer.update(summary: members.count)

      # Without children
      answer = @report.answer(question: table_name, cell: 'C' + row.to_s)
      members = row_universe.where(a_t[:household_type].eq(:adults_only))
      answer.add_members(members)
      answer.update(summary: members.count)

      #  Adults and children
      answer = @report.answer(question: table_name, cell: 'D' + row.to_s)
      members = row_universe.where(a_t[:household_type].eq(:adults_and_children))
      answer.add_members(members)
      answer.update(summary: members.count)

      # Without adults
      answer = @report.answer(question: table_name, cell: 'E' + row.to_s)
      members = row_universe.where(a_t[:household_type].eq(:children_only))
      answer.add_members(members)
      answer.update(summary: members.count)

      # Unknown family type
      answer = @report.answer(question: table_name, cell: 'F' + row.to_s)
      members = row_universe.where(a_t[:household_type].eq(:unknown))
      answer.add_members(members)
      answer.update(summary: members.count)
    end

    private def pit_universe(month:)
      pit_date = pit_date(month: month, before: @report.end_date)
      # For PSH/RRH we care if the HoH has a move in date
      psh_rrh_households = universe.members.where(
        a_t[:first_date_in_program].lteq(pit_date).
          and(a_t[:last_date_in_program].gt(pit_date).
            or(a_t[:last_date_in_program].eq(nil))).
          and(a_t[:move_in_date].lteq(pit_date)).
          and(a_t[:project_type].in([3, 13])).
          and(a_t[:head_of_household].eq(true)),
      ).pluck(:household_id)
      psh_rrh_universe = universe.members.where(
        a_t[:household_id].in(psh_rrh_households).
          and(a_t[:first_date_in_program].lteq(pit_date)).
          and(a_t[:last_date_in_program].gt(pit_date).
            or(a_t[:last_date_in_program].eq(nil))),
      )

      so_serv_ce_universe = universe.members.where(
        a_t[:first_date_in_program].lteq(pit_date).
          and(a_t[:last_date_in_program].gteq(pit_date).
            or(a_t[:last_date_in_program].eq(nil))).
          and(a_t[:project_type].in([4, 6, 14])),
      )
      other_universe = universe.members.where(
        a_t[:first_date_in_program].lteq(pit_date).
          and(a_t[:last_date_in_program].gt(pit_date).
            or(a_t[:last_date_in_program].eq(nil))).
          and(a_t[:project_type].in([2, 8, 9, 10])),
      )

      psh_rrh_universe.or(so_serv_ce_universe).or(other_universe)
    end

    private def pit_date(month:, before:)
      year = before.year if month < before.month
      year = before.year if month == before.month && before.day >= last_wednesday_of(month: before.month, year: before.year).day
      year = before.year - 1 if month > before.month
      year = before.year - 1 if month == before.month && before.day < last_wednesday_of(month: before.month, year: before.year).day

      last_wednesday_of(month: month, year: year)
    end
  end
end
