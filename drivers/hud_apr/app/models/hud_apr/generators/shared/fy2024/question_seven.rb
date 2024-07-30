###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2024
  class QuestionSeven < Base
    QUESTION_NUMBER = 'Question 7'.freeze

    def self.table_descriptions
      {
        'Question 7' => 'Persons Served',
        'Q7a' => 'Number of Persons Served',
        'Q7b' => 'Point-in-Time Count of Persons on the Last Wednesday',
      }.freeze
    end

    private def q7a_persons_served # rubocop:disable Metrics/AbcSize
      table_name = 'Q7a'
      metadata = {
        header_row: header_row,
        row_labels: [
          'Adults',
          'Children',
          label_for(:dkptr),
          'Data Not Collected',
          'Total',
          'For PSH & RRH - the total persons served who moved into housing',
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
          clause: a_t[:dob_quality].in([8, 9]).and(a_t[:dob].eq(nil)),
        },
        # Number of DK/R w/ no children
        {
          cell: 'C4',
          clause: a_t[:dob_quality].in([8, 9]).and(a_t[:dob].eq(nil)).
            and(a_t[:household_type].eq(:adults_only)),
        },
        # Number of DK/R w/ children
        {
          cell: 'D4',
          clause: a_t[:dob_quality].in([8, 9]).and(a_t[:dob].eq(nil)).
            and(a_t[:household_type].eq(:adults_and_children)),
        },
        # Number of DK/R w/ no adults
        {
          cell: 'E4',
          clause: a_t[:dob_quality].in([8, 9]).and(a_t[:dob].eq(nil)).
            and(a_t[:household_type].eq(:children_only)),
        },
        # Number of DK/R in unknown household type
        {
          cell: 'F4',
          clause: a_t[:dob_quality].in([8, 9]).and(a_t[:dob].eq(nil)).
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

      # PSH/RRH w/ move in date
      # OR project type 7 (other) with Funder 35 (Pay for Success)
      ps_rrh_w_move_in = universe.members.where(
        a_t[:project_type].in([3, 13]).
          and(a_t[:move_in_date].not_eq(nil).
          and(a_t[:move_in_date].lteq(@report.end_date))).
          and(a_t[:last_date_in_program].eq(nil).or(a_t[:last_date_in_program].gteq(a_t[:move_in_date]))),
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
      # Logic for step 4 is enforced when addding PIT dates to the client record
      # If a client doesn't have any overlapping enrollments that qualify, they won't
      # have a record for the PIT date
      universe.members.where("pit_enrollments ? '#{pit_date}'")
    end
  end
end
