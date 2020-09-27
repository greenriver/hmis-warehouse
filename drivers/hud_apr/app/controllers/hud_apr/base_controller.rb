###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr
  class BaseController < ApplicationController
    before_action :require_can_view_hud_reports!

    def set_generator(param_name:) # rubocop:disable Naming/AccessorMethodName
      @generator_id = params[param_name].to_i
      @generator = generators[@generator_id]
    end

    def set_report(param_name:) # rubocop:disable Naming/AccessorMethodName
      report_id = params[param_name].to_i
      # APR 0 is the most recent report for the current user
      if report_id.zero?
        @report = @generator.find_report(current_user)
      else
        @report = if can_view_all_hud_reports?
          report_source.find(report_id)
        else
          report_source.where(user_id: current_user.id).find(report_id)
        end
      end
    end

    def filter_options
      filter = params.require(:filter).
        permit(
          :start_date,
          :end_date,
          :coc_code,
          project_ids: [],
        )
      filter[:user_id] = current_user.id
      filter[:project_ids] = filter[:project_ids].reject(&:blank?).map(&:to_i)
      filter
    end

    def generators
      [
        HudApr::Generators::Apr::Fy2020::Generator,
        HudApr::Generators::Caper::Fy2020::Generator,
      ]
    end

    def report_source
      HudReports::ReportInstance
    end

    def report_cell_source
      HudReports::ReportCell
    end

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
