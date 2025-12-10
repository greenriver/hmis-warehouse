###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../../spec/shared_contexts/hud_enrollment_builders'

# Shared context for SPM testing
RSpec.shared_context 'SPM test setup', shared_context: :metadata do
  include_context 'HUD enrollment builders'
  let(:default_filter) do
    Filters::HudFilterBase.new(
      user_id: user.id,
      start: '2022-10-01'.to_date,
      end: '2023-09-30'.to_date,
      coc_codes: ['MA-500'],
      enforce_one_year_range: false,
    )
  end

  def setup_report(project_ids, questions = ['Measure 1'])
    filter = default_filter.dup
    filter.update(project_ids: project_ids)

    report = HudReports::ReportInstance.from_filter(
      filter,
      'System Performance Measures - FY 2026',
      build_for_questions: questions,
    )
    report.question_names = questions
    report.save!

    # Build ServiceHistoryEnrollments
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

    # Generate the SpmEnrollment records
    HudSpmReport::Fy2026::SpmEnrollment.create_enrollment_set(report)

    report
  end

  def run_measure(report, measure_class)
    report.started_at ||= Time.current
    report.save! if report.changed?

    generator = HudSpmReport::Generators::Fy2026::Generator.new(report)
    measure = measure_class.new(generator, report)
    measure.run_question!
    report.reload
  end
end
