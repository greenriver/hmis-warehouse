###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2023
  class QuestionEight < Base
    QUESTION_NUMBER = 'Question 8'.freeze

    HEADER_ROW = [
      ' ',
      'Total',
      'Without Children',
      'With Children and Adults',
      'With Only Children',
      'Unknown Household Type',
    ].freeze

    def self.table_descriptions
      {
        'Question 8' => 'Households Served',
        'Q8a' => 'Number of Households Served',
        'Q8b' => 'Point-in-Time Count of Households on the Last Wednesday',
      }.freeze
    end

    private def q8a_intentionally_blank
      []
    end

    private def q8a4_active_questions
      [
        {
          # w/ no children
          cell: 'C3',
          household_type: :adults_only,
        },
        {
          # w/ children
          cell: 'D3',
          household_type: :adults_and_children,
        },
        {
          # w/ no adults
          cell: 'E3',
          household_type: :children_only,
        },
        {
          # in unknown household type
          cell: 'F3',
          household_type: :unknown,
        },
      ].reject do |q|
        q[:cell].in?(q8a_intentionally_blank)
      end
    end

    private def q8a_persons_served
      table_name = 'Q8a'
      metadata = {
        header_row: HEADER_ROW,
        row_labels: [
          'Total Households',
          'For PSH & RRH - the total households served who moved into housing',
        ],
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 3,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      # Number of households
      heads_of_household = universe.members.where(a_t[:head_of_household].eq(true))

      answer = @report.answer(question: table_name, cell: 'B2')
      members = heads_of_household
      answer.add_members(members)
      answer.update(summary: members.count)

      [
        {
          # Number of households w/ no children
          cell: 'C2',
          household_type: :adults_only,
        },
        {
          # Number of households w/ children
          cell: 'D2',
          household_type: :adults_and_children,
        },
        {
          # Number of households w/ only children
          cell: 'E2',
          household_type: :children_only,
        },
        {
          # Number of households in unknown household type
          cell: 'F2',
          household_type: :unknown,
        },
      ].each do |col|
        answer = @report.answer(question: table_name, cell: col[:cell])
        members = heads_of_household.where(a_t[:household_type].eq(col[:household_type]))
        answer.add_members(members)
        answer.update(summary: members.count)
      end

      # PSH/RRH w/ move in date
      ps_rrh_w_move_in = universe.members.where(
        a_t[:project_type].in([3, 13]).
          and(a_t[:head_of_household].eq(true)).
          and(a_t[:move_in_date].not_eq(nil).
          and(a_t[:move_in_date].lteq(@report.end_date))),
      )
      unless q8a_intentionally_blank.include?('B3')
        answer = @report.answer(question: table_name, cell: 'B3')
        members = ps_rrh_w_move_in
        answer.add_members(members)
        answer.update(summary: members.count)
      end

      q8a4_active_questions.each do |col|
        next if q8a_intentionally_blank.include?(col[:cell])

        answer = @report.answer(question: table_name, cell: col[:cell])
        members = ps_rrh_w_move_in.where(a_t[:household_type].eq(col[:household_type]))
        answer.add_members(members)
        answer.update(summary: members.count)
      end
    end

    private def q8b_pit_count
      table_name = 'Q8b'
      metadata = {
        header_row: HEADER_ROW,
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

      [
        {
          # Without children
          cell: 'C' + row.to_s,
          household_type: :adults_only,
        },
        {
          #  Adults and children
          cell: 'D' + row.to_s,
          household_type: :adults_and_children,
        },
        {
          # Without adults
          cell: 'E' + row.to_s,
          household_type: :children_only,
        },
        {
          # Unknown family type
          cell: 'F' + row.to_s,
          household_type: :unknown,
        },
      ].each do |col|
        answer = @report.answer(question: table_name, cell: col[:cell])
        members = row_universe.where(a_t[:household_type].eq(col[:household_type]))
        answer.add_members(members)
        answer.update(summary: members.count)
      end
    end

    private def pit_universe(month:)
      # NOTE: from AirTable Issue 31, this needs to find households based on any
      # client active on the pit date, then return the HoH for those households.
      # This will catch the edge case where an HoH left, but other members remain
      heads_of_household = universe.members.where(a_t[:head_of_household].eq(true))
      pit_date = pit_date(month: month, before: @report.end_date)
      active_members = universe.members.where("pit_enrollments ? '#{pit_date}'")
      heads_of_household.where(a_t[:household_id].in(active_members.pluck(a_t[:household_id])))
    end
  end
end
