###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2024
  class QuestionTwelve < Base
    QUESTION_NUMBER = 'Question 12'.freeze

    def self.table_descriptions
      {
        'Question 12' => 'Race & Ethnicity',
      }.freeze
    end

    def table_rows
      race_col = a_t[:race_multi]
      [
        {
          label: 'White',
          cond: race_col.eq('5')
        },
        {
          label: 'Asian or Asian American & American Indian, Alaska Native, or Indigenous',
          cond: race_col.eq('1,2')
        },
        {
          label: 'Multiracial – more than 2 races/ethnicity, with one being Hispanic/Latina/e/o',
          # 6 & two or more of 1, 2, 3, 4, 5, or 7
          cond: race_col.matches_regexp('(\d+,){3,}').and(race_col.matches_regexp('\y6\y'))
        },
        {
          label: 'Multiracial – more than 2 races, where no option is Hispanic/Latina/e/o',
          # Three or more of 1, 2, 3, 4, 5, or 7
          cond: race_col.matches_regexp('(\d+,){3,}').and(race_col.does_not_match_regexp('\y6\y'))
        }
      ].each.with_index { |h, idx| h[:number] = 2 + idx }
    end

    def q12a_race_and_ethnicity
      table_name = 'Q12'
      metadata = {
        header_row: [' '] + sub_populations.keys,
        row_labels: races.map { |_, m| m[:label] },
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 34,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      sheet = question_sheet(question: table_name)
      table_rows.each do |row|
        sub_populations.values.each_with_index do |population_clause, col_index|
          sheet.update_cell_members(
            cell: "#{cols[col_index]}#{row[:number]}",
            members: universe.members.where(population_clause).where(row[:cond])
          )
        end
      end
    end
  end
end
