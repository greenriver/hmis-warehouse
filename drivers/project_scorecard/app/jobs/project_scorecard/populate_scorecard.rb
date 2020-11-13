###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ProjectScorecard
  class PopulateScorecard < BaseJob
    queue_as :long_running

    def perform(report_id, send_email, user_id)
      report = report_scope.find(report_id)
      report.update(started_at: Time.current)

      previous = previous_report(report)
      assessment_answers = {}

      if RailsDrivers.loaded.include?(:hud_apr)
        # Generate APR
        filter = ::Filters::FilterBase.new(user_id: user_id)
        filter.set_from_params(
          {
            start: report.start_date,
            end: report.end_date,
            project_ids: [report.project_id],
          },
        )
        questions = [
          'Question 5',
          'Question 6',
          'Question 8',
          'Question 19',
          'Question 22',
          'Question 23',
          'Question 26',
        ]
        generator = HudApr::Generators::Apr::Fy2020::Generator
        apr = HudReports::ReportInstance.from_filter(filter, generator.title, build_for_questions: questions)
        # FIXME: run!(email: false)
        generator.new(apr).run!

        assessment_answers.merge!(
          {
            utilization_jan: answer(apr, 'Q8b', 'B2'),
            utilization_apr: answer(apr, 'Q8b', 'B3'),
            utilization_jul: answer(apr, 'Q8b', 'B4'),
            utilization_oct: answer(apr, 'Q8b', 'B5'),

            chronic_households_served: answer(apr, 'Q26a', 'B2'),
            total_households_served: answer(apr, 'Q26a', 'B6'),

            total_persons_served: answer(apr, 'Q5a', 'B1'),
            total_persons_with_positive_exit: answer(apr, 'Q23c', 'B44'),
            total_persons_exited: answer(apr, 'Q23c', 'B43'),
            excluded_exits: answer(apr, 'Q23c', 'B45'),

            average_los_leavers: answer(apr, 'Q22b', 'B2'),

            percent_pii_errors: answer(apr, 'Q6a', 'F8'),

            days_to_lease_up: answer(apr, 'Q22c', 'B11'),
          },
        )

        # Percent increased income calculations

        leavers_or_annual_expected_with_employment_income = answer(apr, 'Q19a1', 'H2') + answer(apr, 'Q19a2', 'H2')
        increased_employment_income = answer(apr, 'Q19a1', 'I2') + answer(apr, 'Q19a2', 'I2')
        percent_increased_employment_income_at_exit = percentage(increased_employment_income / leavers_or_annual_expected_with_employment_income.to_f)

        leavers_or_annual_expected_with_other_income = answer(apr, 'Q19a1', 'H4') + answer(apr, 'Q19a2', 'H4')
        increased_other_income = answer(apr, 'Q19a1', 'I4') + answer(apr, 'Q19a2', 'I4')
        percent_increased_other_cash_income_at_exit = percentage(increased_other_income / leavers_or_annual_expected_with_other_income.to_f)

        # Data quality calculations
        total_persons_served = answer(apr, 'Q5a', 'B1')

        total_ude_errors = (2..6).map { |row| answer(apr, 'Q6b', 'B' + row.to_s) }.sum
        percent_ude_errors = percentage(total_ude_errors / total_persons_served.to_f)

        total_income_and_housing_errors = (2..5).map { |row| answer(apr, 'Q6c', 'B' + row.to_s) }.sum
        percent_income_and_housing_errors = percentage(total_income_and_housing_errors / total_persons_served.to_f)

        assessment_answers.merge!(
          {
            percent_increased_employment_income_at_exit: percent_increased_employment_income_at_exit,
            percent_increased_other_cash_income_at_exit: percent_increased_other_cash_income_at_exit,
            percent_ude_errors: percent_ude_errors,
            percent_income_and_housing_errors: percent_income_and_housing_errors,
          },
        )
      end

      assessment_answers.merge!(
        {
          percent_returns_to_homelessness: percent_returns_to_homelessness_from_spm(report.start_date, report.end_date, report.project_id, user_id),
        },
      )

      assessment_answers.merge!(
        {
          amount_awarded: previous&.amount_awarded,
          status: 'pre-filled',
        },
      )
      report.update(assessment_answers)
      report.notify_requester
      report.send_email if send_email
    end

    # TODO: When the SPM is updated, this should be too
    private def percent_returns_to_homelessness_from_spm(start_date, end_date, project_id, user_id)
      options = {
        report_start: start_date,
        report_end: end_date,
        project_id: [project_id],
        project_group_ids: [], # Must be included
      }

      report = Reports::SystemPerformance::Fy2019::MeasureTwo.first
      user = User.find(user_id)
      spm = ReportResult.create(
        report: report,
        user: user,
        options: options,
        percent_complete: 0, # start_report looks for this
      )

      measure_two = ReportGenerators::SystemPerformance::Fy2019::MeasureTwo.new(options) # options are ignored, but required
      measure_two.run!
      spm.reload # Get updated values from DB

      number_of_exits = spm.results['two_b7']['value']
      number_of_returns = spm.results['two_i7']['value']

      percentage(number_of_returns / number_of_exits.to_f)
    end

    private def answer(report, table, cell)
      report.answer(question: table, cell: cell).summary
    end

    private def percentage(value)
      format('%1.4f', value.round(4))
    end

    private def previous_report(report)
      report_scope.
        where(project_id: report.project_id).
        where.not(id: report.id).
        order(id: :desc).
        first
    end

    private def report_scope
      ProjectScorecard::Report
    end
  end
end
