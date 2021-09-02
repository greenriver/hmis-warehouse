###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudReports
  class BaseController < ApplicationController
    before_action :require_can_view_hud_reports!

    def download
      respond_to do |format|
        format.html {}
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=#{@report.report_name}.xlsx"
          render template: 'hud_reports/download'
        end
      end
    end

    def set_reports
      title = generator.title
      @reports = report_scope.where(report_name: title).
        preload(:user, :universe_cells)
      @reports = @reports.where(user_id: current_user.id) unless can_view_all_hud_reports?
      @reports = @reports.order(created_at: :desc).
        page(params[:page]).per(25)
    end

    def report_urls
      @report_urls ||= Rails.application.config.hud_reports.map { |_, report| [report[:title], public_send(report[:helper])] }
    end

    private def report_param_name
      :id
    end

    private def set_report
      report_id = params[report_param_name].to_i
      return if report_id.zero?

      @report = if can_view_all_hud_reports?
        report_scope.find(report_id)
      else
        report_scope.where(user_id: current_user.id).find(report_id)
      end
    end

    private def report_scope
      report_source.where(report_name: report_name)
    end

    private def report_source
      ::HudReports::ReportInstance
    end

    private def report_cell_source
      ::HudReports::ReportCell
    end

    private def report_short_name
      generator.short_name
    end
    helper_method :report_short_name

    private def report_name
      generator.title
    end
    helper_method :report_name

    # Required methods in subclasses:
    #
    # private def generator
    # private def path_for_question(question, report: nil)
    # private def path_for_questions(question)
    # private def path_for_question_result(question, report: nil)
    # private def path_for_report(report)
    # private def path_for_reports
    # private def path_for_cell(report:, question:, cell_label:, table:)

    helper_method :generator
    helper_method :path_for_question
    helper_method :path_for_questions
    helper_method :path_for_question_result
    helper_method :path_for_report
    helper_method :path_for_reports
    helper_method :path_for_cell
  end
end
