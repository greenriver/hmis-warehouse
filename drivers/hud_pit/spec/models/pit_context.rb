###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
# frozen_string_literal: true

RSpec.shared_context 'datalab pit context', shared_context: :metadata do
  def shared_filter_spec
    {
      on: Date.parse('2022-09-30'),
      user_id: User.setup_system_user.id,
      coc_codes: ['XX-500', 'XX-501'],
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
