###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2024
  class QuestionFourteen < Base
    QUESTION_NUMBER = 'Question 14'.freeze

    def self.table_descriptions
      {
        'Question 14' => 'Domestic Violence',
        'Q14a' => 'Domestic Violence History',
        'Q14b' => 'Most recent experience of domestic violence, sexual assault, dating violence, stalking, or human trafficking',
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
      dv_members = universe.members.
        where(adult_or_hoh_clause). # only valid for HoH and adults
        where(a_t[:domestic_violence].eq(1)) # Q14b requires DV

      question_sheet(question: 'Q14b') do |sheet|
        sub_populations.keys.each { sheet.add_header(label: _1) }

        occurred_col = a_t[:domestic_violence_occurred]
        [
          ['Within the past three months', occurred_col.eq(1)],
          ['Three to six months ago', occurred_col.eq(2)],
          ['Six months to one year', occurred_col.eq(3)],
          ['One year ago, or more', occurred_col.eq(4)],
          [label_for(:dkptr), occurred_col.in([8, 9])],
          [label_for(:data_not_collected), occurred_col.eq(99).or(occurred_col.eq(nil))],
          ['Total', nil],
        ].each do |label, occurred_cond|
          members = occurred_cond ? dv_members.where(occurred_cond) : dv_members
          sheet.append_row(label: label) do |row|
            sub_populations.values.each do |dv_cond|
              row.append_cell_members(members: members.where(dv_cond))
            end
          end
        end
      end
    end
  end
end
