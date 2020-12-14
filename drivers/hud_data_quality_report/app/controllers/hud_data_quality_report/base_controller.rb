###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudDataQualityReport
  class BaseController < ApplicationController
    before_action :require_can_view_hud_reports!
    before_action :filter

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

    def filter_params
      return {} unless params[:filter]

      filter_p = params.require(:filter).
        permit(
          :start,
          :end,
          coc_codes: [],
          project_ids: [],
          project_type_codes: [],
          project_group_ids: [],
          data_source_ids: [],
        )
      filter_p[:user_id] = current_user.id
      # filter[:project_ids] = filter[:project_ids].reject(&:blank?).map(&:to_i)
      # filter[:project_group_ids] = filter[:project_group_ids].reject(&:blank?).map(&:to_i)
      filter_p
    end

    private def filter
      year = if Date.current.month >= 10
        Date.current.year
      else
        Date.current.year - 1
      end
      # Some sane defaults, using the previous report if available
      @filter = filter_class.new(user_id: current_user.id)
      if filter_params.blank?
        prior_report = generator.find_report(current_user)
        options = prior_report&.options
        site_coc_codes = GrdaWarehouse::Config.get(:site_coc_codes).presence&.split(/,\s*/)
        if options.present?
          @filter.start = options['start'].presence || Date.new(year - 1, 10, 1)
          @filter.end = options['end'].presence || Date.new(year, 9, 30)
          @filter.coc_codes = options['coc_codes'].presence || site_coc_codes
          @filter.project_ids = options['project_ids']
          @filter.project_type_codes = options['project_type_codes']
          @filter.project_group_ids = options['project_group_ids']
          @filter.data_source_ids = options['data_source_ids']
        else
          @filter.start = Date.new(year - 1, 10, 1)
          @filter.end = Date.new(year, 9, 30)
        end
      end
      # Override with params if set
      @filter.set_from_params(filter_params) if filter_params.present?
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

    private def filter_class
      HudDataQualityReport::Filters::DqFilter
    end

    private def generator
      @generator ||= HudDataQualityReport::Generators::Fy2020::Generator
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
      result_hud_reports_dq_question_path(dq_id: report_id, id: id)
    end
    helper_method :path_for_question_result

    private def path_for_question(report_id:, question:)
      hud_reports_dq_question_path(dq_id: report_id, id: question)
    end
    helper_method :path_for_question

    private def path_for_questions(report_id:, question:)
      hud_reports_dq_questions_path(dq_id: report_id, question: question)
    end
    helper_method :path_for_questions

    private def path_for_report(*options)
      hud_reports_dq_path(options)
    end
    helper_method :path_for_report

    def path_for_cell(report_id:, question_id:, cell_id:, table:)
      hud_reports_dq_question_cell_path(dq_id: report_id, question_id: question_id, id: cell_id, table: table)
    end
    helper_method :path_for_cell

    private def path_for_reports(*options)
      hud_reports_dqs_path(options)
    end
    helper_method :path_for_reports
  end
end
