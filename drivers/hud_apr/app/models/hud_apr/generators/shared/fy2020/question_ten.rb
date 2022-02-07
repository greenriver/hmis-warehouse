###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionTen < Base
    QUESTION_NUMBER = 'Question 10'.freeze

    private def table_rows
      {
        'Male' => [2, a_t[:gender].eq(1)],
        'Female' => [3, a_t[:gender].eq(0)],
        'Trans Female (MTF or Male to Female)' => [4, a_t[:gender].eq(2)],
        'Trans Male (FTM or Female to Male)' => [5, a_t[:gender].eq(3)],
        'Gender Non-Conforming (i.e. not exclusively male or female)' => [6, a_t[:gender].eq(4)],
        'Client Doesn\'t Know/Client Refused' => [7, a_t[:gender].in([8, 9])],
        'Data Not Collected' => [8, a_t[:gender].eq(99)],
        'Subtotal' => [9, Arel.sql('1=1')],
      }.freeze
    end

    def self.table_descriptions
      {
        'Question 10' => 'Gender',
        'Q10a' => 'Gender of Adults',
        'Q10b' => 'Gender of Children',
        'Q10c' => 'Gender of Persons Missing Age Information',
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
        'Unknown Household Type',
      ]
      columns = {
        'B' => Arel.sql('1=1'),
        'C' => a_t[:household_type].eq(:adults_only),
        'D' => a_t[:household_type].eq(:adults_and_children),
        'E' => a_t[:household_type].eq(:unknown),
      }

      generate_table(table_name, adult_clause, header_row, columns)
    end

    private def q10b_gender_of_children
      table_name = 'Q10b'
      header_row = [
        ' ',
        'Total',
        'With Children and Adults',
        'With Only Children',
        'Unknown Household Type',
      ]
      columns = {
        'B' => Arel.sql('1=1'),
        'C' => a_t[:household_type].eq(:adults_and_children),
        'D' => a_t[:household_type].eq(:children_only),
        'E' => a_t[:household_type].eq(:unknown),
      }

      generate_table(table_name, child_clause, header_row, columns)
    end

    private def q10c_gender_of_missing_age
      table_name = 'Q10c'
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

      no_age_clause = a_t[:age].eq(nil).or(a_t[:age].lt(0))
      generate_table(table_name, no_age_clause, header_row, columns)
    end

    private def q10d_gender_by_age_range
      table_name = 'Q10d'
      header_row = [
        ' ',
        'Total',
        'Under Age 18',
        'Age 18-24',
        'Age 25-61',
        'Age 62 and over',
        'Client Doesn\'t Know/Client Refused',
        'Data Not Collected',
      ]
      columns = {
        'B' => Arel.sql('1=1'),
        'C' => a_t[:age].between(0..17).and(a_t[:dob_quality].in([1, 2])),
        'D' => a_t[:age].between(18..24).and(a_t[:dob_quality].in([1, 2])),
        'E' => a_t[:age].between(25..61).and(a_t[:dob_quality].in([1, 2])),
        'F' => a_t[:age].gteq(62).and(a_t[:dob_quality].in([1, 2])),
        'G' => a_t[:dob_quality].in([8, 9]),
        'H' => a_t[:dob_quality].not_in([8, 9]).and(a_t[:dob_quality].eq(99).or(a_t[:dob_quality].eq(nil)).or(a_t[:age].lt(0)).or(a_t[:age].eq(nil))),
      }.freeze

      active_clients = Arel.sql('1=1')
      generate_table(table_name, active_clients, header_row, columns)
    end

    private def generate_table(table_name, universe_clause, header_row, columns)
      metadata = {
        header_row: header_row,
        row_labels: table_rows.keys,
        first_column: 'B',
        last_column: columns.keys.last,
        first_row: 2,
        last_row: 9,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      columns.each do |col, columns_clause|
        table_rows.each_value do |row, row_clause|
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
