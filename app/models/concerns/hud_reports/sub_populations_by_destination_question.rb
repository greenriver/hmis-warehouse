###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Required accessors:
#   a_t: Arel Type for the universe model
#

module HudReports::SubPopulationsByDestinationQuestion
  extend ActiveSupport::Concern

  def sub_populations_by_destination_question(question:, members:)
    table_name = question
    first_row = 2
    sheet = question_sheet(question: table_name)
    metadata = {
      header_row: [' '] + sub_populations.keys,
      row_labels: destination_clauses.map(&:first),
      first_column: 'B',
      last_column: 'F',
      first_row: first_row,
      last_row: 43,
    }
    sheet.update_metadata(metadata)
    cols = (metadata[:first_column]..metadata[:last_column]).to_a
    leavers = members.where(leavers_clause)

    sub_populations.values.each_with_index do |population_clause, col_index|
      destination_clauses.map(&:last).each.with_index(first_row) do |destination_clause, row_index|
        next unless destination_clause

        col_letter = cols[col_index]

        members = leavers.where(population_clause)
        if destination_clause.is_a?(Symbol)
          case destination_clause
          when :percentage
            value = percentage(0.0)
            total = sheet.cell_value([col_letter, 40])
            positive = sheet.cell_value([col_letter, 41])
            excluded = sheet.cell_value([col_letter, 42])
            value = percentage(positive.to_f / (total - excluded)) if total.positive? && excluded != total
            sheet.update_cell_value(cell: [col_letter, row_index], value: value) if value
          end
        else
          sheet.update_cell_members(
            cell: [col_letter, row_index],
            members: members.where(destination_clause),
          )
        end
      end
    end
  end
end
