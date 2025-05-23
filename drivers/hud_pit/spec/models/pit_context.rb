###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
# frozen_string_literal: true

RSpec.shared_context 'datalab pit context', shared_context: :metadata do
  let(:pit_date) { '2022-09-30'.to_date }
  let(:user) { User.setup_system_user }
  def shared_filter_spec
    {
      on: pit_date,
      start: pit_date.beginning_of_year,
      end: pit_date.end_of_year,
      user_id: user.id,
      coc_codes: ['XX-500', 'XX-501'],
      coc_codes: ['MA-500'],
      enforce_one_year_range: false,
      require_service_during_range: false,
    }.freeze
  end

  def pit_filter_spec
    shared_filter_spec.merge(
      {
        project_type_codes: HudUtility2024.homeless_project_type_codes,
      },
    )
  end

  def result_file_dir
    'drivers/hud_pit/spec/fixtures/results/'
  end

  def default_pit_filter
    ::Filters::HudFilterBase.new(pit_filter_spec)
  end

  def run(filter, question_numbers)
    klass = HudPit::Generators::Pit::Fy2025::Generator
    report = ::HudReports::ReportInstance.from_filter(
      filter,
      klass.title,
      build_for_questions: question_numbers,
    )
    # Uncomment to get detail CSVs
    # klass.write_detail_path = 'tmp/pit_'
    @generator = klass.new(report)
    @generator.run!

    @report_result = @generator.report
    @report_result.reload
  end
end
