###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr
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
          project_group_ids: [],
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
        if options.present?
          @filter.start = options['start'].presence || Date.new(year - 1, 10, 1)
          @filter.end = options['end'].presence || Date.new(year, 9, 30)
          @filter.coc_codes = options['coc_codes'].presence || GrdaWarehouse::Config.get(:site_coc_codes)
          @filter.project_ids = options['project_ids']
          @filter.project_group_ids = options['project_group_ids']
        else
          @filter.start = Date.new(year - 1, 10, 1)
          @filter.end = Date.new(year, 9, 30)
          @filter.coc_codes = GrdaWarehouse::Config.get(:site_coc_codes)
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

    def report_source
      ::HudReports::ReportInstance
    end

    def report_cell_source
      ::HudReports::ReportCell
    end

    private def filter_class
      HudApr::Filters::AprFilter
    end
  end
end
