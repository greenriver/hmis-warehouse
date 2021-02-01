###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Apr::AprConcern
  extend ActiveSupport::Concern

  included do
    def generator
      @generator ||= HudApr::Generators::Apr::Fy2020::Generator
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
  end
end
