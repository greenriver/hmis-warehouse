###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionTwelve < Base
    QUESTION_NUMBER = 'Question 12'.freeze

    def self.table_descriptions
      {
        'Question 12' => 'Race & Ethnicity',
        'Q12a' => 'Race',
        'Q12b' => 'Ethnicity',
      }.freeze
    end

    private def q12a_race
      table_name = 'Q12a'
      metadata = {
        header_row: [' '] + sub_populations.keys,
        row_labels: races.map { |_, m| m[:label] },
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 10,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      sub_populations.values.each_with_index do |population_clause, col_index|
        races.each_with_index do |(_, race), row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"

          answer = @report.answer(question: table_name, cell: cell)
          members = universe.members.
            where(population_clause).
            where(race[:clause])
          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    private def q12b_ethnicity
      table_name = 'Q12b'
      metadata = {
        header_row: [' '] + sub_populations.keys,
        row_labels: ethnicities.map { |_, m| m[:label] },
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 6,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      sub_populations.values.each_with_index do |population_clause, col_index|
        ethnicities.each_with_index do |(_, ethnicity), row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"

          answer = @report.answer(question: table_name, cell: cell)
          members = universe.members.
            where(population_clause).
            where(ethnicity[:clause])
          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end
  end
end
