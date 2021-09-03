###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2021
  class QuestionFourteen < Base
    QUESTION_NUMBER = 'Question 14'.freeze

    def self.table_descriptions
      {
        'Question 14' => 'Domestic Violence',
        'Q14a' => 'Domestic Violence History',
        'Q14b' => 'Persons Fleeing Domestic Violence',
      }.freeze
    end

    private def q14a_dv_history
      table_name = 'Q14a'
      metadata = {
        header_row: [' '] + sub_populations.keys,
        row_labels: yes_know_dkn_clauses(a_t[:domestic_violence]).keys,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 6,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      sub_populations.values.each_with_index do |population_clause, col_index|
        yes_know_dkn_clauses(a_t[:domestic_violence]).values.each_with_index do |dv_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.
            where(adult_or_hoh_clause). # only valid for HoH and adults
            where(population_clause).
            where(dv_clause)
          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    private def q14b_dv_fleeing
      table_name = 'Q14b'
      metadata = {
        header_row: [' '] + sub_populations.keys,
        row_labels: yes_know_dkn_clauses(a_t[:domestic_violence]).keys,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 6,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      sub_populations.values.each_with_index do |population_clause, col_index|
        yes_know_dkn_clauses(a_t[:domestic_violence]).values.each_with_index do |dv_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"

          answer = @report.answer(question: table_name, cell: cell)
          members = universe.members.
            where(adult_or_hoh_clause). # only valid for HoH and adults
            where(a_t[:currently_fleeing].eq(1)). # Q14b requires currently fleeing
            where(population_clause).
            where(dv_clause)
          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end
  end
end
