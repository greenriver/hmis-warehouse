###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionTwenty < Base
    QUESTION_NUMBER = 'Question 20'.freeze
    QUESTION_TABLE_NUMBERS = ['Q20a', 'Q20b'].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q20a_types
      q20b_sources

      @report.complete(QUESTION_NUMBER)
    end

    private def q20a_types
      table_name = 'Q20a'
      metadata = {
        header_row: [' '] + income_stage.keys,
        row_labels: income_types(:start).keys,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 6,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      income_stage.each_with_index do |(_, suffix), col_index|
        income_types(suffix).to_a.each_with_index do |(_, income_clause), row_index|
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
      income_stage.each_with_index do |(_, suffix), col_index|
        counted = Set.new
        income_counts(suffix).to_a.each_with_index do |(_, income_clause), row_index|
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

    private def income_types(suffix)
      {
        'Supplemental Nutrition Assistance Program (SNAP) (Previously known as Food Stamps)' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { SNAP: 1 } } },
        'Special Supplemental Nutrition Program for Women, Infants, and Children (WIC)' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { WIC: 1 } } },
        'TANF Child Care Services' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { TANFChildCare: 1 } } },
        'TANF Transportation Services' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { TANFTransportation: 1 } } },
        'Other TANF-Funded Services' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { OtherTANF: 1 } } },
        'Other Source' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { OtherBenefitsSource: 1 } } },
      }
    end

    private def intentionally_blank
      [].freeze
    end

    private def universe
      @universe ||= build_universe(
        QUESTION_NUMBER,
        preloads: {
          enrollment: [
            :client,
            :income_benefits,
            :income_benefits_at_exit,
            :income_benefits_at_entry,
            :income_benefits_annual_update,
          ],
        },
      ) do |_, enrollments|
        last_service_history_enrollment = enrollments.last
        enrollment = last_service_history_enrollment.enrollment
        source_client = enrollment.client
        client_start_date = [@report.start_date, last_service_history_enrollment.first_date_in_program].max
        exit_date = last_service_history_enrollment.last_date_in_program
        exit_record = last_service_history_enrollment.enrollment if exit_date.present? && exit_date < @report.end_date

        income_at_start = enrollment.income_benefits_at_entry
        income_at_annual_assessment = annual_assessment(enrollment)
        income_at_exit = exit_record&.income_benefits_at_exit

        report_client_universe.new(
          client_id: source_client.id,
          data_source_id: source_client.data_source_id,
          report_instance_id: @report.id,

          age: source_client.age_on(client_start_date),
          first_date_in_program: last_service_history_enrollment.first_date_in_program,
          last_date_in_program: last_service_history_enrollment.last_date_in_program,
          head_of_household: last_service_history_enrollment[:head_of_household],
          head_of_household_id: last_service_history_enrollment.head_of_household_id,
          length_of_stay: stay_length(last_service_history_enrollment),
          annual_assessment_expected: annual_assessment_expected?(last_service_history_enrollment),
          income_from_any_source_at_start: income_at_start&.IncomeFromAnySource,
          income_from_any_source_at_annual_assessment: income_at_annual_assessment&.IncomeFromAnySource,
          income_from_any_source_at_exit: income_at_exit&.IncomeFromAnySource,
          income_total_at_start: income_at_start&.hud_total_monthly_income&.to_i,
          income_total_at_annual_assessment: income_at_annual_assessment&.hud_total_monthly_income&.to_i,
          income_total_at_exit: income_at_exit&.hud_total_monthly_income&.to_i,
          income_sources_at_start: income_sources(income_at_start),
          income_sources_at_annual_assessment: income_sources(income_at_annual_assessment),
          income_sources_at_exit: income_sources(income_at_exit),
          non_cash_benefits_from_any_source_at_start: income_at_start&.BenefitsFromAnySource,
          non_cash_benefits_from_any_source_at_annual_assessment: income_at_annual_assessment&.BenefitsFromAnySource,
          non_cash_benefits_from_any_source_at_exit: income_at_exit&.BenefitsFromAnySource,
        )
      end
    end
  end
end
