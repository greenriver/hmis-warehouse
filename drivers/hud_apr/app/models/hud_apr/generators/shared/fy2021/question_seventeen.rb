###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2021
  class QuestionSeventeen < Base
    QUESTION_NUMBER = 'Question 17'.freeze

    def self.table_descriptions
      {
        'Question 17' => 'Cash Income - Sources',
      }.freeze
    end

    private def q17_cash_sources
      table_name = 'Q17'
      metadata = {
        header_row: [' '] + income_stages.keys,
        row_labels: income_headers,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 17,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      income_stages.values.each_with_index do |suffix, col_index|
        income_types(suffix).values.each_with_index do |income_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)
          members = universe.members.where(adult_clause)

          answer.update(summary: 0) and next if members.count.zero?

          if income_clause.is_a?(Hash)
            members = members.where.contains(income_clause)
          else
            # The final question doesn't require accessing the jsonb column
            members = members.where(income_clause)
          end
          members = members.where(stayers_clause) if suffix == :annual_assessment
          members = members.where(leavers_clause) if suffix == :exit
          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    private def income_headers
      income_types('').keys
    end

    private def income_stages
      {
        'Income at Start' => :start,
        'Income at Latest Annual Assessment for Stayers' => :annual_assessment,
        'Income at Exit for Leavers' => :exit,
      }
    end

    private def intentionally_blank
      [
        'B17',
      ].freeze
    end
  end
end
