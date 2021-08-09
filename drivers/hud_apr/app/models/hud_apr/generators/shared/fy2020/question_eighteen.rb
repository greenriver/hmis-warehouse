###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionEighteen < Base
    QUESTION_NUMBER = 'Question 18'.freeze

    private def q18_income
      table_name = 'Q18'
      metadata = {
        header_row: [' '] + income_stages.keys,
        row_labels: income_headers,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 12,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      income_stages.values.each_with_index do |suffix, col_index|
        income_responses(suffix).values.each_with_index do |income_case, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)
          adults = universe.members.where(adult_clause)

          case suffix
          when :annual_assessment
            adults = adults.where(stayers_clause)
            # C8-10 will either add their own requirements or should include everyone
            adults = adults.where(a_t[:annual_assessment_expected].eq(true)) unless cell.in?(annual_assessment_clause_not_required)
          when :exit
            adults = adults.where(leavers_clause)
          end

          ids = Set.new
          if income_case.is_a?(Symbol)
            adults.preload(:universe_membership).find_each do |member|
              apr_client = member.universe_membership
              case income_case
              when :earned
                ids << member.id if earned_income?(apr_client, suffix) && ! other_income?(apr_client, suffix)
              when :other
                ids << member.id if other_income?(apr_client, suffix) && ! earned_income?(apr_client, suffix)
              when :both
                ids << member.id if both_income_types?(apr_client, suffix)
              when :none
                ids << member.id if no_income?(apr_client, suffix)
              end
            end
            members = adults.where(id: ids)
          else
            members = adults.where(income_case)
          end

          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    private def annual_assessment_clause_not_required
      [
        'C8',
        'C9',
        'C10',
      ]
    end

    private def income_headers
      income_responses('').keys
    end

    private def income_stages
      {
        'Number of Adults at Start' => :start,
        'Number of Adults at Annual Assessment (Stayers)' => :annual_assessment,
        'Number of Adults at Exit (Leavers)' => :exit,
      }
    end

    private def intentionally_blank
      [
        'B8',
        'B9',
        'B12',
        'D8',
        'D9',
      ].freeze
    end
  end
end
