###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Required accessors:
#   a_t: Arel Type for the universe model
#
module HudReports::SubPopulationsBySubsidyTypeQuestion
  extend ActiveSupport::Concern

  def sub_populations_by_subsidy_type_question(question:, members:)
    sheet = question_sheet(question: question)

    # Leavers in the report date range with an exit destination of 435 (“Rental by client, with housing subsidy”).
    leavers = members.where(leavers_clause).where(a_t[:destination].eq(435))

    first_row = 2
    metadata = {
      header_row: [' '] + sub_populations.keys,
      row_labels: HudUtility2024.rental_subsidy_types.values + ['Total'],
      first_column: 'B',
      last_column: 'F',
      first_row: first_row,
      last_row: 13,
    }
    sheet.update_metadata(metadata)

    cols = (metadata[:first_column]..metadata[:last_column]).to_a
    sub_populations.values.each.with_index do |population_clause, col_index|
      scope = leavers.where(population_clause)
      HudUtility2024.rental_subsidy_types.keys.each.with_index(2) do |code, row_index|
        sheet.update_cell_members(
          cell: [cols[col_index], row_index],
          members: scope.where(a_t[:exit_destination_subsidy_type].eq(code)),
        )
      end
      sheet.update_cell_members(
        cell: [cols[col_index], 13],
        members: scope,
      )
    end
  end
end
