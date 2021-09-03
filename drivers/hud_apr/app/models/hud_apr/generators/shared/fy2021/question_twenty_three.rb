###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2021
  class QuestionTwentyThree < Base
    QUESTION_NUMBER = 'Question 23'.freeze

    def self.table_descriptions
      {
        'Question 23' => '',
        'Q23c' => 'Exit Destination',
      }.freeze
    end

    private def q23c_destination
      table_name = 'Q23c'
      metadata = {
        header_row: [' '] + q23c_populations.keys,
        row_labels: q23c_destinations_headers,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 46,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a

      leavers = universe.members.where(leavers_clause)

      q23c_populations.values.each_with_index do |population_clause, col_index|
        q23c_destinations.values.each_with_index do |destination_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = leavers.where(population_clause)
          if destination_clause.is_a?(Symbol)
            case destination_clause
            when :percentage
              value = percentage(0.0)
              positive = members.where(q23c_destinations['Total persons exiting to positive housing destinations']).count
              total = members.where(q23c_destinations['Total']).count
              excluded = members.where(q23c_destinations['Total persons whose destinations excluded them from the calculation']).count
              value = percentage(positive.to_f / (total - excluded)) if total.positive? && excluded != total
            end
          else
            members = members.where(destination_clause)
            value = members.count
          end
          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q23c_destinations_headers
      q23c_destinations.keys.map do |label|
        next 'Subtotal' if label.include?('Subtotal')

        label
      end
    end

    private def q23c_populations
      sub_populations
    end

    private def q23c_destinations
      destination_clauses
    end

    private def intentionally_blank
      [
        'B2',
        'C2',
        'D2',
        'E2',
        'F2',
        'B17',
        'C17',
        'D17',
        'E17',
        'F17',
        'B28',
        'C28',
        'D28',
        'E28',
        'F28',
        'B36',
        'C36',
        'D36',
        'E36',
        'F36',
      ].freeze
    end
  end
end
