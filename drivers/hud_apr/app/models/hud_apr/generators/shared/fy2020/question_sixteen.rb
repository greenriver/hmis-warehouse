###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionSixteen < Base
    QUESTION_NUMBER = 'Question 16'.freeze
    QUESTION_TABLE_NUMBERS = ['Q16'].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    private def q16_cash_ranges
      table_name = 'Q16'
      metadata = {
        header_row: [' '] + income_stages.keys,
        row_labels: income_headers,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 14,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      income_stages.values.each_with_index do |suffix, col_index|
        income_levels(suffix).values.each_with_index do |income_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)
          members = universe.members.
            where(adult_clause).
            where(income_clause)
          members = members.where(stayers_clause) if suffix == :annual_assessment
          members = members.where(leavers_clause) if suffix == :exit
          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    private def income_headers
      income_levels('').keys
    end

    private def income_stages
      {
        'Income at Start' => :start,
        'Income at Latest Annual Assessment for Stayers' => :annual_assessment,
        'Income at Exit for Leavers' => :exit,
      }
    end

    private def income_levels(suffix)
      {
        'No Income' => a_t["income_total_at_#{suffix}".to_sym].eq(0),
        '$1 - $150' => a_t["income_total_at_#{suffix}".to_sym].between(1..150),
        '$151 - $250' => a_t["income_total_at_#{suffix}".to_sym].between(151..250),
        '$251 - $500' => a_t["income_total_at_#{suffix}".to_sym].between(251..500),
        '$501 - $1,000' => a_t["income_total_at_#{suffix}".to_sym].between(501..1_000),
        '$1,001 - $1,500' => a_t["income_total_at_#{suffix}".to_sym].between(1_001..1_500),
        '$1,501 - $2,000' => a_t["income_total_at_#{suffix}".to_sym].between(1_501..2_000),
        '$2,001+' => a_t["income_total_at_#{suffix}".to_sym].gt(2_000),
        'Client Doesn’t Know/Client Refused' => a_t["income_total_at_#{suffix}".to_sym].eq(nil).
          and(a_t["income_from_any_source_at_#{suffix}".to_sym].in([8, 9])),
        'Data Not Collected' => a_t["income_total_at_#{suffix}".to_sym].eq(nil).
          and(
            a_t["income_from_any_source_at_#{suffix}".to_sym].eq(99).
            or(a_t["income_from_any_source_at_#{suffix}".to_sym].eq(nil)),
          ),
        'Number of adult stayers not yet required to have an annual assessment' => adult_clause.
          and(stayers_clause).
          and(a_t[:annual_assessment_expected].eq(false)),
        'Number of adult stayers without required annual assessment' => adult_clause.
          and(stayers_clause).
          and(a_t[:annual_assessment_expected].eq(true)).
          and(a_t[:income_from_any_source_at_annual_assessment].eq(nil)),
        'Total Adults' => Arel.sql('1=1'),
      }
    end

    private def intentionally_blank
      [
        'B12',
        'B13',
        'D12',
        'D13',
      ].freeze
    end

    private def universe
      batch_initializer = ->(clients_with_enrollments) do
        @household_types = {}
        clients_with_enrollments.each do |_, enrollments|
          last_service_history_enrollment = enrollments.last
          hh_id = last_service_history_enrollment.household_id
          @household_types[hh_id] = household_makeup(hh_id, [@report.start_date, last_service_history_enrollment.first_date_in_program].max)
        end
      end

      @universe ||= build_universe(
        QUESTION_NUMBER,
        before_block: batch_initializer,
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
          annual_assessment_expected: annual_assessment_expected?(last_service_history_enrollment),
          income_from_any_source_at_start: income_at_start&.IncomeFromAnySource,
          income_from_any_source_at_annual_assessment: income_at_annual_assessment&.IncomeFromAnySource,
          income_from_any_source_at_exit: income_at_exit&.IncomeFromAnySource,
          income_total_at_start: income_at_start&.hud_total_monthly_income,
          income_total_at_annual_assessment: income_at_annual_assessment&.hud_total_monthly_income,
          income_total_at_exit: income_at_exit&.hud_total_monthly_income,
          household_type: @household_types[last_service_history_enrollment.household_id],
        )
      end
    end
  end
end
