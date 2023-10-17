###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2024
  class QuestionTen < Base
    QUESTION_NUMBER = 'Question 10'.freeze

    def self.table_descriptions
      {
        'Question 10' => 'Gender',
        'Q10a' => 'Gender',
        'Q10d' => 'Gender by Age Ranges',
      }.freeze
    end

    private def q10a_gender_of_adults
      table_name = 'Q10a'
      header_row = [
        ' ',
        'Total',
        'Without Children',
        'With Children and Adults',
        'With Only Children',
        'Unknown Household Type',
      ]
      columns = {
        'B' => Arel.sql('1=1'),
        'C' => a_t[:household_type].eq(:adults_only),
        'D' => a_t[:household_type].eq(:adults_and_children),
        'E' => a_t[:household_type].eq(:children_only),
        'F' => a_t[:household_type].eq(:unknown),
      }

      generate_table(table_name, adult_clause, header_row, columns)
    end

    private def q10d_gender_by_age_range
      table_name = 'Q10d'
      header_row = [
        ' ',
        'Total',
        'Under Age 18',
        'Age 18-24',
        'Age 25-64',
        'Age 65+',
        label_for(:dkptr),
        'Data Not Collected',
      ]
      columns = {
        'B' => Arel.sql('1=1'),
        'C' => a_t[:age].between(0..17),
        'D' => a_t[:age].between(18..24),
        'E' => a_t[:age].between(25..65),
        'F' => a_t[:age].gteq(65),
        'G' => a_t[:dob_quality].in([8, 9]).and(a_t[:dob].eq(nil)),
        'H' => a_t[:dob_quality].not_in([8, 9]).
          and(a_t[:dob_quality].eq(99).and([a_t[:age].eq(nil)]).
            or(a_t[:dob_quality].eq(nil)).
            or(a_t[:age].lt(0)).or(a_t[:age].eq(nil))),
      }.freeze

      active_clients = Arel.sql('1=1')
      generate_table(table_name, active_clients, header_row, columns)
    end

    private def generate_table(table_name, universe_clause, header_row, columns)
      metadata = {
        header_row: header_row,
        row_labels: gender_identities.keys,
        first_column: 'B',
        last_column: columns.keys.last,
        first_row: 2,
        last_row: 33,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      columns.each do |col, columns_clause|
        gender_identities.each_value do |row, row_clause|
          cell = "#{col}#{row}"
          answer = @report.answer(question: table_name, cell: cell)
          members = universe.members.
            where(universe_clause).
            where(columns_clause).
            where(row_clause)
          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end
  end
end
