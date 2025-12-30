# frozen_string_literal: true

require 'rails_helper'

# Shared context for common HUD report testing patterns
# Provides base utilities used across SPM, APR DQ
RSpec.shared_context 'HUD report test helpers', shared_context: :metadata do
  # Default user setup with CoC codes
  # Override in specific contexts if different user type needed
  let(:user) do
    user = User.setup_system_user
    user.coc_codes = ['MA-500']
    user
  end

  # Creates a filter with standard test defaults
  # Override specific parameters in tests or contexts as needed
  def create_hud_filter(
    user: self.user,
    start_date: Date.new(2022, 10, 1),
    end_date: Date.new(2023, 9, 30),
    coc_codes: ['MA-500'],
    enforce_one_year_range: false,
    **additional_options
  )
    Filters::HudFilterBase.new(
      {
        user: user,
        start: start_date,
        end: end_date,
        coc_codes: coc_codes,
        enforce_one_year_range: enforce_one_year_range,
      }.merge(additional_options),
    )
  end

  # Generates unique household IDs for test data
  def household_id_generator
    @household_id_generator ||= Enumerator.new do |y|
      i = 0
      loop { y << "HH-#{SecureRandom.uuid}-#{i += 1}" }
    end
  end

  # Rebuilds service history for all enrollments
  # Call after creating enrollment test data
  def rebuild_service_history!
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
  end

  # Creates a report instance from a filter
  def create_report_instance(filter:, report_title:, questions: [])
    report = HudReports::ReportInstance.from_filter(
      filter,
      report_title,
      build_for_questions: questions,
    )
    report.question_names = questions
    report.save!
    report
  end

  # Common pattern: setup report with project IDs and rebuild service history
  def setup_basic_report(base_filter:, project_ids:, report_title:, questions:)
    filter = base_filter.dup
    filter.update(project_ids: project_ids)

    report = create_report_instance(
      filter: filter,
      report_title: report_title,
      questions: questions,
    )

    rebuild_service_history!

    report
  end

  # Runs a report question/measure with standard setup
  def run_report_question(report:, generator_class:, question_class:)
    report.started_at ||= Time.current
    report.save! if report.changed?

    generator = generator_class.new(report)
    question = question_class.new(generator, report)
    question.run_question!
    report.reload
  end
end
