RSpec.shared_context 'datalab spm context', shared_context: :metadata do
  def spm_filter_spec
    shared_filter_spec.merge(
      {
        project_type_codes: GrdaWarehouse::Hud::Project::SPM_PROJECT_TYPE_CODES,
      },
    )
  end

  def default_spm_filter
    ::Filters::HudFilterBase.new(spm_filter_spec)
  end

  def run(filter, question_numbers)
    klass = HudSpmReport::Generators::Fy2020::Generator
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
