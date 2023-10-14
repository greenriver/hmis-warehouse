###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2024
  class QuestionTwentyThree < Base
    QUESTION_NUMBER = 'Question 23'.freeze

    def self.table_descriptions
      {
        'Question 23' => '',
        'Q23c' => 'Exit Destination',
        'Q23d' => 'Exit Destination – Subsidy Type of Persons Exiting to Rental by Client With An Ongoing Subsidy',
      }.freeze
    end

    def q23c_destination
      table_name = 'Q23c'
      first_row = 2
      sheet = question_sheet(question: table_name)
      metadata = {
        header_row: [' '] + q23c_populations.keys,
        row_labels: q23c_destinations.map(&:first),
        first_column: 'B',
        last_column: 'F',
        first_row: first_row,
        last_row: 43,
      }
      sheet.update_metadata(metadata)
      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      leavers = universe.members.where(leavers_clause)

      q23c_populations.values.each_with_index do |population_clause, col_index|
        q23c_destinations.map(&:last).each.with_index(first_row) do |destination_clause, row_index|
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
              sheet.update_cell_value( cell: [col_letter, row_index], value: value) if value
            end
          else
            sheet.update_cell_members(
              cell: [col_letter, row_index],
              members: members.where(destination_clause)
            )
          end
        end
      end
    end

    def q23d_subsidy_type
      sheet = question_sheet(question: 'Q23d')

      # Leavers in the report date range with an exit destination of 435 (“Rental by client, with housing subsidy”).
      leavers = universe.members.where(leavers_clause).where(a_t[:destination].eq(435))

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
            members: scope.where(a_t[:exit_destination_subsidy_type].eq(code))
          )
        end
        sheet.update_cell_members(
          cell: [cols[col_index], 13],
          members: scope
        )
      end
    end

    private def q23c_populations
      sub_populations
    end

    private def q23c_destinations
      destination_clauses
    end
  end
end
