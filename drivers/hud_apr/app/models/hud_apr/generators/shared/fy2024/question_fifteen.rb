###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2024
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
        last_row: 32,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      sub_populations.values.each_with_index do |population_clause, col_index|
        living_situations.map(&:last).each.with_index(2) do |situation_clause, row_index|
          cell = "#{cols[col_index]}#{row_index}"
          next unless situation_clause

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
      living_situations.map(&:first)
    end
  end
end
