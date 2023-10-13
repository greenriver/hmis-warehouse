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

    def q12a_race_and_ethnicity
      first_row = 2
      table_rows = all_table_rows
      last_row = first_row + table_rows.size

      sheet = question_sheet(question: 'Q12')
      metadata = {
        header_row: [' '] + sub_populations.keys,
        row_labels: table_rows.map { |r| r[:label] } + ['Total'],
        first_column: 'B',
        last_column: 'F',
        first_row: first_row,
        last_row: last_row,
      }
      sheet.update_metadata(metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      totals = []
      table_rows.each.with_index(first_row) do |row, row_index|
        sub_populations.values.each.with_index do |population_clause, col_index|
          cell = sheet.update_cell_members(
            cell: "#{cols[col_index]}#{row_index}",
            members: universe.members.where(population_clause).where(row[:cond]),
          )
          totals[col_index] ||= []
          totals[col_index] += cell.members
        end
      end

      # totals row
      sub_populations.values.each_with_index do |_, col_index|
        sheet.update_cell_members(
          cell: "#{cols[col_index]}#{last_row}",
          members: totals[col_index],
        )
      end
    end

    RACE_CODE_LABELS = {
      1 => 'American Indian, Alaska Native, or Indigenous',
      2 => 'Asian or Asian American',
      3 => 'Black, African American, or African',
      4 => 'Native Hawaiian or Pacific Islander',
      5 => 'White',
      6 => 'Hispanic/Latina/e/o',
      7 => 'Middle Eastern or North African',
    }.freeze

    def race_label(ids)
      ids.map { RACE_CODE_LABELS.fetch(_1) }.join(' & ')
    end

    def all_table_rows
      race_col = a_t[:race_multi]
      codes = [1, 2, 3, 6, 7, 4, 5] # order is by sorted label

      ret = []
      # one race
      codes.each do |code|
        ret << {
          label: race_label([code]),
          cond: race_col.eq(code.to_s),
        }
      end
      [
        [2, 1],
        [3, 1],
        [6, 1],
        [7, 1],
        [4, 1],
        [5, 1],
        [3, 2],
        [6, 2],
        [7, 2],
        [4, 2],
        [5, 2],
        [6, 3],
        [7, 3],
        [4, 3],
        [5, 3],
        [2, 3],
        [7, 6],
        [4, 6],
        [5, 6],
        [4, 7],
        [5, 4],
      ].each do |combo|
        ret << {
          label: race_label(combo),
          cond: race_col.eq(combo.sort.join(',')),
        }
      end
      ret + [
        {
          label: 'Multiracial – more than 2 races/ethnicity, with one being Hispanic/Latina/e/o',
          # 6 & two or more of 1, 2, 3, 4, 5, or 7
          cond: race_col.matches_regexp('(\d+,){3,}').and(race_col.matches_regexp('\y6\y')),
        },
        {
          label: 'Multiracial – more than 2 races, where no option is Hispanic/Latina/e/o',
          # Three or more of 1, 2, 3, 4, 5, or 7
          cond: race_col.matches_regexp('(\d+,){3,}').and(race_col.does_not_match_regexp('\y6\y')),
        },
        {
          label: label_for(:dkptr),
          cond: race_col.eq('8').or(race_col.eq('9')),
        },
        {
          label: label_for(:data_not_collected),
          cond: race_col.eq(nil).or(race_col.eq('99')),
        },
      ]
    end
  end
end
