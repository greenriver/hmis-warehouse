###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2024
  class QuestionTwentyThree < Base
    include HudReports::SubPopulationsBySubsidyTypeQuestion
    include HudReports::SubPopulationsByDestinationQuestion

    QUESTION_NUMBER = 'Question 23'.freeze

    def self.table_descriptions
      {
        'Question 23' => '',
        'Q23c' => 'Exit Destination',
        'Q23d' => 'Exit Destination – Subsidy Type of Persons Exiting to Rental by Client With An Ongoing Subsidy',
        'Q23e' => 'Exit Destination Type by Race and Ethnicity',
      }.freeze
    end

    def q23c_destination
      sub_populations_by_destination_question(question: 'Q23c', members: universe.members)
    end

    def q23d_subsidy_type
      sub_populations_by_subsidy_type_question(question: 'Q23d', members: universe.members)
    end

    def q23e_destination_type_by_race_and_ethnicity
      sheet = question_sheet(question: 'Q23e')

      leavers = universe.members.where(leavers_clause)
      groups = [{ label: 'Total', cond: nil }] + race_ethnicity_groups

      first_row = 2
      metadata = {
        header_row: [''] + groups.map { _1[:label] },
        row_labels: [
          'Homeless Situations',
          'Institutional Situations',
          'Temporary Situations',
          'Permanent Situations',
          'Other Situations',
          'Total',
        ],
        first_column: 'B',
        last_column: 'L',
        first_row: first_row,
        last_row: 7,
      }
      sheet.update_metadata(metadata)

      col_letters = (metadata[:first_column]..metadata[:last_column]).to_a
      groups.each.with_index do |group, idx|
        group_scope = group[:cond] ? leavers.where(group[:cond]) : leavers
        letter = col_letters.fetch(idx)

        # homeless
        sheet.update_cell_members(
          cell: [letter, 2],
          members: group_scope.where(a_t[:destination].in(100..199)),
        )
        # institutional
        sheet.update_cell_members(
          cell: [letter, 3],
          members: group_scope.where(a_t[:destination].in(200..299)),
        )
        # temporary
        sheet.update_cell_members(
          cell: [letter, 4],
          members: group_scope.where(a_t[:destination].in(300..399)),
        )
        # permanent
        sheet.update_cell_members(
          cell: [letter, 5],
          members: group_scope.where(a_t[:destination].in(400..499)),
        )
        sheet.update_cell_members(
          cell: [letter, 6],
          members: group_scope.where(a_t[:destination].in(1..99).or(a_t[:destination].eq(nil))),
        )
        sheet.update_cell_members(
          cell: [letter, 7],
          members: group_scope,
        )
      end
    end
  end
end
