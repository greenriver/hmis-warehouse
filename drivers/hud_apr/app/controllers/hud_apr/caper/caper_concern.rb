###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Caper::CaperConcern
  extend ActiveSupport::Concern

  included do
    def generator
      @generator ||= HudApr::Generators::Caper::Fy2020::Generator
    end
    helper_method :generator

    private def report_short_name
      generator.short_name
    end
    helper_method :report_short_name

    private def report_name
      generator.title
    end
    helper_method :report_name

    private def path_for_question_result(report_id:, id:)
      result_hud_reports_caper_question_path(caper_id: report_id, id: id)
    end
    helper_method :path_for_question_result

    private def path_for_question(report_id:, question:)
      hud_reports_caper_question_path(caper_id: report_id, id: question)
    end
    helper_method :path_for_question

    private def path_for_questions(report_id:, question:)
      hud_reports_caper_questions_path(caper_id: report_id, question: question)
    end
    helper_method :path_for_questions

    private def path_for_report(*options)
      hud_reports_caper_path(options)
    end
    helper_method :path_for_report

    private def path_for_reports(*options)
      hud_reports_capers_path(options)
    end
    helper_method :path_for_reports
  end
end
