###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../../../spec/shared_contexts/hud_enrollment_builders'

RSpec.shared_context 'HUD CE APR FY2026 setup', shared_context: :metadata do
  include_context 'HUD enrollment builders'

  let(:user) do
    User.setup_system_user
  end

  let(:ce_apr_filter) do
    Filters::HudFilterBase.new(
      user: user,
      start: Date.new(2025, 10, 1),
      end: Date.new(2026, 9, 30),
      coc_codes: ['MA-500'],
      enforce_one_year_range: false,
    )
  end

  def setup_ce_apr_report(project_ids)
    questions = HudApr::Generators::CeApr::Fy2026::Generator.questions.keys
    filter = ce_apr_filter.dup
    filter.update(project_ids: Array(project_ids))

    report = HudReports::ReportInstance.from_filter(
      filter,
      HudApr::Generators::CeApr::Fy2026::Generator.title,
      build_for_questions: questions,
    )
    report.question_names = questions
    report.save!

    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

    report
  end

  def run_ce_apr_report(report)
    Reporting::Hud::RunReportJob.new.perform(
      'HudApr::Generators::CeApr::Fy2026::Generator',
      report.id,
      email: false,
    )
    report.reload
  end
end
