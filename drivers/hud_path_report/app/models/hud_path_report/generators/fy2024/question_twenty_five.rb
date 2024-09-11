###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport::Generators::Fy2024
  class QuestionTwentyFive < Base
    include ArelHelper

    QUESTION_NUMBER = 'Q25: Housing Outcomes'.freeze
    QUESTION_TABLE_NUMBER = 'Q25'.freeze
    QUESTION_TABLE_NUMBERS = [QUESTION_TABLE_NUMBER].freeze

    TABLE_HEADER = [
      '25. Destination at Exit',
      'count',
    ].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])
      table_name = QUESTION_TABLE_NUMBER

      metadata = {
        header_row: TABLE_HEADER,
        row_labels: prior_living_situation_rows.map(&:first),
        first_column: 'B',
        last_column: 'B',
        first_row: 2,
        last_row: 42,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      sum = 0
      sum_members = []
      prior_living_situation_rows.each_with_index do |(_label, destination), index|
        answer = @report.answer(question: table_name, cell: 'B' + (index + 2).to_s)
        case destination
        when nil # Internal label, leave blank
          next
        when :subtotal # Section sums
          answer.update(summary: sum)
          sum = 0
          answer.add_members(sum_members)
          sum_members = []
          next
        when :stayers
          members = universe.members.where(active_and_enrolled_clients).where(stayers)
        when :total
          members = universe.members.where(active_and_enrolled_clients)
        else
          query = a_t[:destination].eq(destination)
          # Also recognize leavers w/ blank destinations as 'not collected'
          query = query.or(a_t[:last_date_in_program].not_eq(nil).and(a_t[:destination].eq(nil))) if destination == 99
          members = universe.members.where(active_and_enrolled_clients).where(leavers).where(query)
        end
        answer.add_members(members)
        sum_members += members
        count = members.count
        sum += count
        answer.update(summary: count)
      end

      @report.complete(QUESTION_NUMBER)
    end

    def prior_living_situation_rows
      excluded_values = [336, 335].to_set
      # 204, then 205
      # no 336, 335
      PRIOR_LIVING_SITUATION_ROWS.filter do |_, v, q|
        next if q.present? && q != QUESTION_TABLE_NUMBER

        !v.in?(excluded_values)
      end
    end
  end
end
