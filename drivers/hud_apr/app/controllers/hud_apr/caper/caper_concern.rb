###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Caper::CaperConcern
  extend ActiveSupport::Concern

  included do
    def generator
      @generator ||= begin
        version = filter_params[:report_version]&.to_sym || @report&.options&.try(:[], 'report_version') || @filter&.report_version || default_report_version
        case version.to_sym
        when :fy2020
          HudApr::Generators::Caper::Fy2020::Generator
        when :fy2021
          HudApr::Generators::Caper::Fy2021::Generator
        end
      end
    end

    private def path_for_question(question, report: nil)
      hud_reports_caper_question_path(caper_id: report&.id || 0, id: question)
    end

    private def path_for_questions(question)
      hud_reports_caper_questions_path(caper_id: 0, question: question)
    end

    private def path_for_question_result(question, report: nil)
      result_hud_reports_caper_question_path(caper_id: report&.id || 0, id: question)
    end

    private def path_for_report(*options)
      hud_reports_caper_path(options)
    end

    private def path_for_reports(*options)
      hud_reports_capers_path(options)
    end

    private def path_for_cell(report:, question:, cell_label:, table:)
      hud_reports_caper_question_cell_path(caper_id: report&.id || 0, question_id: question, id: cell_label, table: table)
    end

    private def path_for_running_all_questions
      running_all_questions_hud_reports_capers_path
    end

    private def path_for_running_question
      running_hud_reports_capers_path(link_params.except('action', 'controller'))
    end

    private def path_for_history(args = nil)
      history_hud_reports_capers_path(args)
    end
    helper_method :path_for_history

    def path_for_report_download(report, args)
      download_hud_reports_caper_path(report, args)
    end
    helper_method :path_for_report_download

    private def path_for_new
      new_hud_reports_caper_path
    end
    helper_method :path_for_new

    private def set_pdf_export
      @pdf_export = HudApr::DocumentExports::HudCaperExport.new
    end

    private def possible_generator_classes
      [
        HudApr::Generators::Caper::Fy2020::Generator,
        HudApr::Generators::Caper::Fy2021::Generator,
      ]
    end
  end
end
