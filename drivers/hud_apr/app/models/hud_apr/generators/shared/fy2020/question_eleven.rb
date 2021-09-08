###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionEleven < Base
    QUESTION_NUMBER = 'Question 11'.freeze

    def self.table_descriptions
      {
        'Question 11' => 'Age',
      }.freeze
    end

    private def q11_ages
      table_name = 'Q11'
      metadata = {
        header_row: [' '] + sub_populations.keys,
        row_labels: age_ranges.keys,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 13,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      sub_populations.values.each_with_index do |population_clause, col_index|
        age_ranges.values.each_with_index do |age_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)
          members = universe.members.
            where(population_clause).
            where(age_clause)
          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    private def intentionally_blank
      [
        'C2',
        'C3',
        'C4',
        'E5',
        'E6',
        'E7',
        'E8',
        'E9',
        'E10',
      ].freeze
    end
  end
end
