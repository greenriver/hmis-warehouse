###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2024
  class QuestionTen < Base
    QUESTION_NUMBER = 'Question 10'.freeze

    private def table_rows
      gender_col = a_t[:gender_multi]
      {
        'Woman' => [2, gender_col.eq('0')],
        'Man' => [3, gender_col.eq('1')],
        'Culturally Specific Identity' => [4, gender_col.eq('2')],
        'Transgender' => [5, gender_col.eq('5')],
        'Non-Binary' => [6, gender_col.eq('4')],
        'Questioning' => [7, gender_col.eq('6')],
        'Different Identity' => [8, gender_col.eq('3')],

        'Woman/Man' => [9, gender_col.eq('0,1')],
        'Woman/Culturally Specific Identity' => [10, gender_col.eq('0,2')],
        'Woman/Transgender' => [11, gender_col.eq('0,5')],
        'Woman/Non-Binary' => [12, gender_col.eq('0,4')],
        'Woman/Questioning' => [13, gender_col.eq('0,6')],
        'Woman/Different Identity' => [14, gender_col.eq('0,3')],

        'Man/Culturally Specific Identity' => [15, gender_col.eq('1,2')],
        'Man/Transgender' => [16, gender_col.eq('1,5')],
        'Man/Non-Binary' => [17, gender_col.eq('1,4')],
        'Man/Questioning' => [18, gender_col.eq('1,6')],
        'Man/Different Identity' => [19, gender_col.eq('1,3')],

        'Culturally Specific Identity/Transgender' => [20, gender_col.eq('2,5')],
        'Culturally Specific Identity/Non-Binary' => [21, gender_col.eq('2,4')],
        'Culturally Specific Identity/Questioning' => [22, gender_col.eq('2,6')],
        'Culturally Specific Identity/Different Identity' => [23, gender_col.eq('2,3')],

        'Transgender/Non-Binary' => [24, gender_col.eq('5,4')],
        'Transgender/Questioning' => [25, gender_col.eq('5,6')],
        'Transgender/Different Identity' => [26, gender_col.eq('5,3')],

        'Non-Binary/Questioning' => [27, gender_col.eq('4,6')],
        'Non-Binary/Different Identity' => [28, gender_col.eq('4,3')],

        'Questioning/Different Identity' => [29, gender_col.eq('6,3')],
        # 2 or more commas
        'More than 2 Gender Identities Selected' => [30, gender_col.matches_regexp('(\d+,){2,}')],
        label_for(:dkptr) => [31, gender_col.in(['8', '9'])],
        'Data Not Collected' => [32, gender_col.eq('99')],
        'Total' => [33, Arel.sql('1=1')],
      }.freeze
    end

    def self.table_descriptions
      {
        'Question 10' => 'Gender',
        'Q10a' => 'Gender',
        # 'Q10b' => 'Gender of Children',
        # 'Q10c' => 'Gender of Persons Missing Age Information',
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
        row_labels: table_rows.keys,
        first_column: 'B',
        last_column: columns.keys.last,
        first_row: 2,
        last_row: 33,
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
