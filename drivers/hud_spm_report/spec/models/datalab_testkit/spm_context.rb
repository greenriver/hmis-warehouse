###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'datalab spm context', shared_context: :metadata do
  def shared_filter_spec
    {
      start: Date.parse('2021-10-01'),
      end: Date.parse('2022-09-30'),
      user_id: User.setup_system_user.id,
      coc_codes: ['XX-500', 'XX-501'], # maybe 'XX-518' also?
    }.freeze
  end

  def spm_filter_spec
    shared_filter_spec.merge(
      {
        project_type_codes: HudUtility2024.spm_project_type_codes,
      },
    )
  end

  def default_spm_filter
    ::Filters::HudFilterBase.new(spm_filter_spec)
  end

  def run(filter, question_numbers)
    klass = HudSpmReport::Generators::Fy2023::Generator
    @generator = klass.new(
      ::HudReports::ReportInstance.from_filter(
        filter,
        klass.title,
        build_for_questions: question_numbers,
      ),
    )
    @generator.run!

    @report_result = @generator.report
    @report_result.reload
  end
end
