###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionFifteen < Base
    QUESTION_NUMBER = 'Question 15'.freeze

    def self.table_descriptions
      {
        'Question 15' => 'Living Situation',
      }.freeze
    end

    private def q15_living_situation
      table_name = 'Q15'
      metadata = {
        header_row: [' '] + sub_populations.keys,
        row_labels: living_situation_headers,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 35,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      sub_populations.values.each_with_index do |population_clause, col_index|
        living_situations.values.each_with_index do |situation_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)
          members = universe.members.
            where(adult_or_hoh_clause).
            where(population_clause).
            where(situation_clause)
          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    private def living_situation_headers
      living_situations.keys.map do |label|
        next 'Subtotal' if label.include?('Subtotal')

        label
      end
    end

    private def intentionally_blank
      [
        'B2',
        'C2',
        'D2',
        'E2',
        'F2',
        'B9',
        'C9',
        'D9',
        'E9',
        'F9',
        'B18',
        'C18',
        'D18',
        'E18',
        'F18',
      ].freeze
    end
  end
end
