###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Caper::CaperConcern
  extend ActiveSupport::Concern

  included do
    def generator
      @generator ||= HudApr::Generators::Caper::Fy2020::Generator
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

    private def set_pdf_export
      @pdf_export = HudApr::DocumentExports::HudCaperExport.new
    end
  end
end
