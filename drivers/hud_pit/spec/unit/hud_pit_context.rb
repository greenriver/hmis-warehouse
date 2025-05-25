###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
# frozen_string_literal: true

require_relative '../../../../spec/shared_contexts/hud_enrollment_builders'

RSpec.shared_context 'HUD pit context', shared_context: :metadata do
  include_context 'HUD enrollment builders'

  let(:pit_date) { '2024-01-28'.to_date }
  let(:user) { User.setup_system_user }
  let(:filter_params) do
    {
      on: pit_date,
      start: pit_date.beginning_of_year,
      end: pit_date.end_of_year,
      user_id: user.id,
      coc_codes: ['MA-500'],
      enforce_one_year_range: false,
      require_service_during_range: false,
      project_type_codes: HudUtility2024.homeless_project_type_codes,
    }
  end

  def run_report(filter: filter_params, questions:)
    # Build ServiceHistoryEnrollments
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
    # Calculate chronic status
    GrdaWarehouse::ChEnrollment.maintain!

    filter = ::Filters::HudFilterBase.new(filter_params)
    klass = HudPit::Generators::Pit::Fy2025::Generator
    report = ::HudReports::ReportInstance.from_filter(
      filter,
      klass.title,
      build_for_questions: questions,
    )
    # Uncomment to get detail CSVs
    # klass.write_detail_path = 'tmp/pit_'
    generator = klass.new(report)
    generator.run!

    result = generator.report
    result.reload
    result
  end
end
