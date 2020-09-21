###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Apr::Fy2020
  class QuestionEighteen < HudApr::Generators::Shared::Fy2020::Base
    QUESTION_NUMBER = 'Question 18'.freeze
    QUESTION_TABLE_NUMBER = 'Q18'.freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])

      metadata = {
        header_row: [' '] + income_stages.keys,
        row_labels: income_headers,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 12,
      }
      @report.answer(question: QUESTION_TABLE_NUMBER).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      income_stages.each_with_index do |(_, suffix), col_index|
        income_types(suffix).to_a.each_with_index do |(_, income_case), row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: QUESTION_TABLE_NUMBER, cell: cell)
          adults = universe.members.where(adult_clause)
          adults = adults.where(stayers_clause) if suffix == :annual_assessment
          adults = adults.where(leavers_clause) if suffix == :exit

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

      @report.complete(QUESTION_NUMBER)
    end

    private def income_headers
      income_types('').keys
    end

    private def income_stages
      {
        'Number of Adults at Start' => :start,
        'Number of Adults at Annual Assessment (Stayers)' => :annual_assessment,
        'Number of Adults at Exit (Leavers)' => :exit,
      }
    end

    private def income_types(suffix)
      {
        'Adults with Only Earned Income (i.e., Employment Income)' => :earned,
        'Adults with Only Other Income' => :other,
        'Adults with Both Earned and Other Income' => :both,
        'Adults with No Income' => :none,
        'Adults with Client Doesn’t Know/Client Refused Income Information' => a_t["income_from_any_source_at_#{suffix}"].in([8, 9]),
        'Adults with Missing Income Information' => a_t["income_from_any_source_at_#{suffix}"].eq(99).
          or(a_t["income_from_any_source_at_#{suffix}"].eq(nil)).
          and(a_t["income_sources_at_#{suffix}"].not_eq(nil)),
        'Number of adult stayers not yet required to have an annual assessment' => adult_clause.
          and(stayers_clause).
          and(a_t[:annual_assessment_expected].eq(false)),
        'Number of adult stayers without required annual assessment' => adult_clause.
          and(stayers_clause).
          and(a_t[:annual_assessment_expected].eq(true)).
          and(a_t[:income_from_any_source_at_annual_assessment].eq(nil)),
        'Total Adults' => Arel.sql('1=1'),
        '1 or more source of income' => a_t["income_total_at_#{suffix}"].gt(0),
        'Adults with Income Information at Start and Annual Assessment/Exit' => a_t['income_from_any_source_at_start'].in([0, 1]).and(a_t["income_from_any_source_at_#{suffix}"].in([0, 1])),
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
          annual_assessment_expected: annual_assessment_expected?(last_service_history_enrollment),
          income_from_any_source_at_start: income_at_start&.IncomeFromAnySource,
          income_from_any_source_at_annual_assessment: income_at_annual_assessment&.IncomeFromAnySource,
          income_from_any_source_at_exit: income_at_exit&.IncomeFromAnySource,
          income_total_at_start: income_at_start&.hud_total_monthly_income,
          income_total_at_annual_assessment: income_at_annual_assessment&.hud_total_monthly_income,
          income_total_at_exit: income_at_exit&.hud_total_monthly_income,
          income_sources_at_start: income_sources(income_at_start),
          income_sources_at_annual_assessment: income_sources(income_at_annual_assessment),
          income_sources_at_exit: income_sources(income_at_exit),
        )
      end
    end
  end
end
