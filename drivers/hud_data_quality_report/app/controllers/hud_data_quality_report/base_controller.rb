###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudDataQualityReport
  class BaseController < ::HudReports::BaseController
    before_action :filter

    def available_report_versions
      {
        'FY 2020' => { slug: :fy2020, active: false },
        'FY 2022' => { slug: :fy2022, active: true },
      }.freeze
    end
    helper_method :available_report_versions

    def default_report_version
      :fy2022
    end

    private def filter_class
      ::Filters::HudFilterBase
    end

    private def path_for_question(question, report: nil, args: {})
      hud_reports_dq_question_path({ dq_id: report&.id || 0, id: question }.merge(args))
    end

    private def path_for_questions(question)
      hud_reports_dq_questions_path(dq_id: 0, question: question)
    end

    private def path_for_question_result(question, report: nil)
      result_hud_reports_dq_question_path(dq_id: report&.id || 0, id: question)
    end

    private def path_for_report(report)
      hud_reports_dq_path(report)
    end

    private def path_for_reports
      hud_reports_dqs_path
    end

    private def path_for_cell(report:, question:, cell_label:, table:)
      hud_reports_dq_question_cell_path(dq_id: report.id, question_id: question, id: cell_label, table: table)
    end

    private def path_for_running_all_questions
      running_all_questions_hud_reports_dqs_path(link_params.except('action', 'controller'))
    end

    private def path_for_running_question
      running_hud_reports_dqs_path(link_params.except('action', 'controller'))
    end

    private def path_for_history(args = nil)
      history_hud_reports_dqs_path(args)
    end
    helper_method :path_for_history

    def path_for_report_download(report, args)
      download_hud_reports_dq_path(report, args)
    end
    helper_method :path_for_report_download

    private def path_for_new
      new_hud_reports_dq_path
    end
    helper_method :path_for_new

    private def set_pdf_export
      @pdf_export = HudDataQualityReport::DocumentExports::HudDataQualityReportExport.new
    end

    private def possible_generator_classes
      {
        fy2020: HudDataQualityReport::Generators::Fy2020::Generator,
        fy2022: HudDataQualityReport::Generators::Fy2022::Generator,
      }
    end
  end
end
