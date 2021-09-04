###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudDataQualityReport
  class BaseController < ::HudReports::BaseController
    before_action :filter

    def available_report_versions
      {
        'FY 2020' => :fy2020,
        'FY 2021' => :fy2021,
      }.freeze
    end
    helper_method :available_report_versions

    def default_report_version
      :fy2020
    end

    private def filter_class
      ::HudDataQualityReport::Filters::DqFilter
    end

    def generator
      @generator ||= begin
        case filter_params[:report_version]&.to_sym || @filter&.report_version || default_report_version
        when :fy2020
          HudDataQualityReport::Generators::Fy2020::Generator
        when :fy2021
          HudDataQualityReport::Generators::Fy2021::Generator
        end
      end
    end
    helper_method :generator

    private def path_for_question(question, report: nil)
      hud_reports_dq_question_path(dq_id: report&.id || 0, id: question)
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
      running_all_questions_hud_reports_dqs_path
    end

    private def path_for_running_question
      running_hud_reports_dqs_path(link_params.except('action', 'controller'))
    end

    private def path_for_history(args = nil)
      history_hud_reports_dqs_path(args)
    end
    private def set_pdf_export
      @pdf_export = HudDataQualityReport::DocumentExports::HudDataQualityReportExport.new
    end

    private def possible_generator_classes
      [
        HudDataQualityReport::Generators::Fy2020::Generator,
        HudDataQualityReport::Generators::Fy2021::Generator,
      ]
    end
  end
end
