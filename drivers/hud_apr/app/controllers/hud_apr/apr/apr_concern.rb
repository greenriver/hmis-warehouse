###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Apr::AprConcern
  extend ActiveSupport::Concern

  included do
    def generator
      @generator ||= begin
        version = filter_params[:report_version]&.to_sym || @report&.options&.try(:[], 'report_version') || @filter&.report_version || default_report_version
        case version.to_sym
        when :fy2020
          HudApr::Generators::Apr::Fy2020::Generator
        when :fy2021
          HudApr::Generators::Apr::Fy2021::Generator
        end
      end
    end

    private def path_for_question(question, report: nil)
      hud_reports_apr_question_path(apr_id: report&.id || 0, id: question)
    end

    private def path_for_questions(question)
      hud_reports_apr_questions_path(apr_id: 0, question: question)
    end

    private def path_for_question_result(question, report: nil)
      result_hud_reports_apr_question_path(apr_id: report&.id || 0, id: question)
    end

    private def path_for_report(*options)
      hud_reports_apr_path(options)
    end

    private def path_for_reports(*options)
      hud_reports_aprs_path(options)
    end

    private def path_for_cell(report:, question:, cell_label:, table:)
      hud_reports_apr_question_cell_path(apr_id: report&.id || 0, question_id: question, id: cell_label, table: table)
    end

    private def path_for_running_all_questions
      running_all_questions_hud_reports_aprs_path
    end

    private def path_for_running_question
      running_hud_reports_aprs_path(link_params.except('action', 'controller'))
    end

    private def path_for_history(args = nil)
      history_hud_reports_aprs_path(args)
    end
    helper_method :path_for_history

    def path_for_report_download(report, args)
      download_hud_reports_apr_path(report, args)
    end
    helper_method :path_for_report_download

    private def set_pdf_export
      @pdf_export = HudApr::DocumentExports::HudAprExport.new
    end

    private def possible_generator_classes
      [
        HudApr::Generators::Apr::Fy2020::Generator,
        HudApr::Generators::Apr::Fy2021::Generator,
      ]
    end
  end
end
