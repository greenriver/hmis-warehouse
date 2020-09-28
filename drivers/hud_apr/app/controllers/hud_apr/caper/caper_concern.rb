###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Caper::CaperConcern
  extend ActiveSupport::Concern

  included do
    def generators
      [
        HudApr::Generators::Caper::Fy2020::Generator,
      ]
    end

    private def report_short_name
      'CAPER'
    end
    helper_method :report_short_name

    private def report_name
      'Consolidated Annual Performance and Evaluation Report - FY 2020'
    end
    helper_method :report_name

    private def path_for_question_result(report_id:, id:)
      result_hud_reports_caper_question_path(caper_id: report_id, id: id)
    end
    helper_method :path_for_question_result

    private def path_for_question(report_id:, id:)
      hud_reports_caper_question_path(caper_id: report_id, id: id)
    end
    helper_method :path_for_question

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
