###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr
  class AprsController < BaseController
    before_action -> { set_generator(param_name: :generator) }, except: [:index, :running_all_questions]
    before_action -> { set_report(param_name: :id) }, only: [:show, :edit, :destroy, :running]
    before_action :set_reports, except: [:index, :running_all_questions]

    def index
      @tab_content_reports = Report.active.order(weight: :asc, type: :desc).map(&:report_group_name).uniq
      @report_urls = report_urls
      @generators = generators
      @path_for_running = running_all_questions_hud_reports_aprs_path
    end

    def running_all_questions
      index
    end

    def show
      respond_to do |format|
        format.html do
          @questions = @generator.questions.keys
          @contents = @report&.completed_questions
          @options = options_struct
          @path_for_running = running_hud_reports_aprs_path(link_params.except('action', 'controller'))
        end
        format.zip do
          exporter = HudReports::ZipExporter.new(@report)
          date = Date.current.strftime('%Y-%m-%d')
          send_data exporter.export!, filename: "apr-#{date}.zip"
        end
      end
    end

    def running
      @questions = @generator.questions.keys
      @contents = @report&.completed_questions
      @options = options_struct
      @path_for_running = running_hud_reports_aprs_path(link_params.except('action', 'controller'))
    end

    def edit
      @options = options_struct
    end

    def update
      gen = @generator.new(filter_options)
      gen.run!
      redirect_to hud_reports_apr_path(0, generator: @generator_id)
    end

    def destroy
      @report.destroy
      redirect_to hud_reports_apr_path(0, generator: @generator_id)
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
      @reports = report_source.where(report_name: titles).
        preload(:user, :universe_cells)
      @reports = @reports.where(user_id: current_user.id) unless can_view_all_hud_reports?
      @reports = @reports.order(created_at: :desc).
        page(params[:page]).per(25)
    end

    def report_urls
      @report_urls ||= Rails.application.config.hud_reports.map { |_, report| [report[:title], public_send(report[:helper])] }
    end
  end
end
