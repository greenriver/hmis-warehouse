###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ContinuumSemiAnnualPerformance
  # Runs the APR for each project type, and the CE APR where the report has a CE tab,
  # as the requesting user. Each sub-report gets explicit project ids so it can't widen
  # the selection.
  class SubReportRunner
    class CocUnavailable < StandardError; end

    def initialize(report)
      @report = report
    end

    # @return [Hash{Symbol => HudReports::ReportInstance}] the sub-reports that ran, by project type
    def run
      verify_coc!

      report.project_types.each_with_object({}) do |project_type, results|
        project_ids = report.project_ids_for(project_type)
        next if project_ids.empty?

        results[project_type] = run_sub_report(project_type, project_ids)
      end
    end

    private

    attr_reader :report

    # Filter#update drops a CoC the user can no longer use. Running without it would cover every CoC.
    def verify_coc!
      filter_codes = Array(report.filter.coc_codes)
      stored_codes = Array(report.options.with_indifferent_access[:coc_codes])
      return if filter_codes.size == 1 && filter_codes == stored_codes

      raise CocUnavailable, "CoC #{stored_codes.join(', ').presence || '(none)'} is not available to this user"
    end

    def run_sub_report(project_type, project_ids)
      generator = project_type == :ce_tab ? HudApr.current_generator(report: :ce_apr) : HudApr.current_generator(report: :apr)
      hud_report = HudReports::ReportInstance.from_filter(
        sub_report_filter(project_ids),
        generator.title,
        build_for_questions: RowDefinitions.questions(report.row_set, project_type),
      )
      generator.new(hud_report).run!(email: false, manual: false)
      hud_report
    end

    def sub_report_filter(project_ids)
      ::Filters::HudFilterBase.new(
        user_id: report.user_id,
        enforce_one_year_range: false,
        start: report.filter.start,
        end: report.filter.end,
        coc_codes: report.filter.coc_codes,
        project_ids: project_ids,
      )
    end
  end
end
