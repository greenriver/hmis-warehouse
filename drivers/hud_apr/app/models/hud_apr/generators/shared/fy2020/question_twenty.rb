###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionTwenty < Base
    QUESTION_NUMBER = 'Question 20'.freeze

    def self.table_descriptions
      {
        'Question 20' => 'Non-Cash Benefits',
        'Q20a' => 'Type of Non-Cash Benefit Sources',
        'Q20b' => 'Number of Non-Cash Benefit Sources',
      }.freeze
    end

    private def q20a_types
      table_name = 'Q20a'
      metadata = {
        header_row: [' '] + income_stage.keys,
        row_labels: non_cash_benefit_types(:start).keys,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 7,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      income_stage.values.each_with_index do |suffix, col_index|
        non_cash_benefit_types(suffix).values.each_with_index do |income_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(adult_clause)
          case suffix
          when :annual_assessment
            members = members.where(stayers_clause).
              where(a_t[:annual_assessment_expected].eq(true))
          when :exit
            # non-HoH clients are limited to those who exited on or after the HoH
            # For leavers, report only heads of households who left plus other adult household members who left at the same time as the head of household. Do not include household members who left prior to the head of household even though that person is otherwise considered a “leaver” in other report questions.
            additional_leaver_ids = Set.new
            members.where(leavers_clause).where(a_t[:head_of_household].eq(false)).
              pluck(a_t[:id], a_t[:head_of_household_id], a_t[:last_date_in_program]).each do |id, hoh_id, exit_date|
                hoh_exit_date = hoh_exit_dates[hoh_id]
                additional_leaver_ids << id if exit_date.blank? || hoh_exit_date.blank? || exit_date >= hoh_exit_date
              end
            members = members.where(leavers_clause).where(hoh_clause.or(a_t[:id].in(additional_leaver_ids)))
          end

          answer.update(summary: 0) and next if members.count.zero?

          members = members.where.contains(income_clause)
          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    private def q20b_sources
      table_name = 'Q20b'
      metadata = {
        header_row: [' '] + income_stage.keys,
        row_labels: income_counts(:start).keys,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 6,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      income_stage.values.each_with_index do |suffix, col_index|
        counted = Set.new
        income_counts(suffix).values.each_with_index do |income_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(adult_clause)
          case suffix
          when :annual_assessment
            members = members.where(stayers_clause).
              where(a_t[:annual_assessment_expected].eq(true))
          when :exit
            # non-HoH clients are limited to those who exited on or after the HoH
            # For leavers, report only heads of households who left plus other adult household members who left at the same time as the head of household. Do not include household members who left prior to the head of household even though that person is otherwise considered a “leaver” in other report questions.
            additional_leaver_ids = Set.new
            members.where(leavers_clause).where(a_t[:head_of_household].eq(false)).
              pluck(a_t[:id], a_t[:head_of_household_id], a_t[:last_date_in_program]).each do |id, hoh_id, exit_date|
                hoh_exit_date = hoh_exit_dates[hoh_id]
                additional_leaver_ids << id if exit_date.blank? || hoh_exit_date.blank? || exit_date >= hoh_exit_date
              end
            members = members.where(leavers_clause).where(hoh_clause.or(a_t[:id].in(additional_leaver_ids)))
          end

          # Row 5 is everyone not counted in 2, 3, or 4
          if rows[row_index] == 5
            members = members.where(a_t[:id].not_in(counted))
          else
            members = members.where(income_clause)
            counted += members.pluck(a_t[:id])
          end
          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    private def income_stage
      {
        'Benefit at Start' => :start,
        'Benefit at Latest Annual Assessment for Stayers' => :annual_assessment,
        'Benefit at Exit for Leavers' => :exit,
      }
    end

    private def income_counts(suffix)
      {
        'No Sources' => a_t["non_cash_benefits_from_any_source_at_#{suffix}"].eq(0).
          and(benefit_jsonb_clause(1, a_t["income_sources_at_#{suffix}"].to_sql, negation: true)).
          and(benefit_jsonb_clause(99, a_t["income_sources_at_#{suffix}"].to_sql, negation: true)),
        '1 + Source(s)' => a_t["non_cash_benefits_from_any_source_at_#{suffix}"].eq(1).
          and(benefit_jsonb_clause(1, a_t["income_sources_at_#{suffix}"].to_sql)),
        "Client Doesn't Know/Client Refused" => a_t["non_cash_benefits_from_any_source_at_#{suffix}"].in([8, 9]),
        # This needs to also include to those who have non_cash_benefits_from_any_source_at_ == 0 but also have 1s or 99s in the sources
        # and those who have non_cash_benefits_from_any_source_at_ == 1 but don't have any 1s in the sources
        'Data Not Collected/Not stayed long enough for Annual Assessment' => a_t["non_cash_benefits_from_any_source_at_#{suffix}"].not_in([0, 1, 8, 9]),
        'Total' => Arel.sql('1=1'),
      }
    end

    private def intentionally_blank
      [].freeze
    end
  end
end
