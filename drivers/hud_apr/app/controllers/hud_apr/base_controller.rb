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
      # id: 0 is the most recent report for the current user
      # or a new report if there are none
      if report_id.zero?
        @report = @generator.find_report(current_user)
      else
        @report = if can_view_all_hud_reports?
          report_scope.find(report_id)
        else
          report_scope.where(user_id: current_user.id).find(report_id)
        end
      end
    end

    def options_struct
      options = @report&.options || {}
      @options = OpenStruct.new(
        start_date: options['start_date']&.to_date || Date.current.last_month.beginning_of_month.last_year,
        end_date: options['end_date']&.to_date || Date.current.last_month.end_of_month,
        coc_code: options['coc_code'] || GrdaWarehouse::Config.get(:site_coc_codes),
        project_ids: options['project_ids']&.map(&:to_i),
      )
    end

    def set_reports
      titles = generators.map(&:title)
      @reports = report_scope.where(report_name: titles).
        preload(:user, :universe_cells)
      @reports = @reports.where(user_id: current_user.id) unless can_view_all_hud_reports?
      @reports = @reports.order(created_at: :desc).
        page(params[:page]).per(25)
    end

    def report_urls
      @report_urls ||= Rails.application.config.hud_reports.map { |_, report| [report[:title], public_send(report[:helper])] }
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

    private def report_scope
      report_source.where(report_name: report_name)
    end

    def report_source
      HudReports::ReportInstance
    end

    def report_cell_source
      HudReports::ReportCell
    end
  end
end
