###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Required accessors:
#   a_t: Arel Type for the universe model
#

module HudReports::LivingSituationsQuestion
  extend ActiveSupport::Concern

  def living_situations_question(question:, members:)
    table_name = question
    metadata = {
      header_row: [' '] + sub_populations.keys,
      row_labels: living_situations.map(&:first),
      first_column: 'B',
      last_column: 'F',
      first_row: 2,
      last_row: 32,
    }
    @report.answer(question: question).update(metadata: metadata)

    cols = (metadata[:first_column]..metadata[:last_column]).to_a
    sub_populations.values.each_with_index do |population_clause, col_index|
      living_situations.map(&:last).each.with_index(2) do |situation_clause, row_index|
        cell = "#{cols[col_index]}#{row_index}"
        next unless situation_clause

        answer = @report.answer(question: table_name, cell: cell)
        scope = members.
          where(population_clause).
          where(situation_clause)
        answer.add_members(scope)
        answer.update(summary: scope.count)
      end
    end
  end
end
