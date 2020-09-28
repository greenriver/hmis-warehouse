###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Apr::AprConcern
  extend ActiveSupport::Concern

  included do
    def generators
      [
        HudApr::Generators::Apr::Fy2020::Generator,
      ]
    end

    private def report_short_name
      'APR'
    end
    helper_method :report_short_name

    private def report_name
      'Annual Performance Report - FY 2020'
    end
    helper_method :report_name

    private def path_for_question_result(report_id:, id:)
      result_hud_reports_apr_question_path(apr_id: report_id, id: id)
    end
    helper_method :path_for_question_result

    private def path_for_question(report_id:, id:)
      hud_reports_apr_question_path(apr_id: report_id, id: id)
    end
    helper_method :path_for_question

    private def path_for_report(*options)
      hud_reports_apr_path(options)
    end
    helper_method :path_for_report

    private def path_for_reports(*options)
      hud_reports_aprs_path(options)
    end
    helper_method :path_for_reports
  end
end
