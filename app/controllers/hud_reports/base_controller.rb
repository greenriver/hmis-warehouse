###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudReports
  class BaseController < ApplicationController
    before_action :require_can_view_hud_reports!
    before_action :set_view_filter, only: [:show]

    def set_reports
      title = generator.title
      @reports = report_scope.where(report_name: title).
        preload(:user, :universe_cells)
      if can_view_all_hud_reports? && @view_filter.present?
        @reports = @reports.where(user_id: @view_filter[:creator])
      else
        @reports = @reports.where(user_id: current_user.id)
      end
      if @view_filter.present? && @view_filter[:initiator] == 'automated'
        @reports = @reports.automated
      else
        @reports = @reports.manual
      end
      @reports = @reports.where(created_at: @view_filter[:start].to_date..(@view_filter[:end].to_date + 1.days)) if @view_filter.present?
      # TODO: add view filter @view_filter
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

    private def view_filter_params
      params.permit(
        :initiator,
        :creator,
        :start,
        :end,
      )
    end

    private def set_view_filter
      @view_filter = {}
      @view_filter[:initiator] = view_filter_params[:initiator] || :manual
      @view_filter[:creator] = view_filter_params[:creator] || current_user.id
      @view_filter[:start] = view_filter_params[:start] || (Date.current - 1.month)
      @view_filter[:end] = view_filter_params[:end] || Date.current
      @active_filter = view_filter_params.present?
    end

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
