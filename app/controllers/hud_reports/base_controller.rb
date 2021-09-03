###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudReports
  class BaseController < ApplicationController
    before_action :require_can_view_hud_reports!

    def index
      @tab_content_reports = Report.active.order(weight: :asc, type: :desc).map(&:report_group_name).uniq
      @report_urls = report_urls
      @path_for_running = path_for_running_all_questions
    end

    def running_all_questions
      index
    end

    def show
      respond_to do |format|
        format.html do
          @show_recent = params[:id].to_i.positive?
          @questions = generator.questions.keys
          @contents = @report&.completed_questions
          @path_for_running = path_for_running_question
        end
        format.zip do
          exporter = ::HudReports::ZipExporter.new(@report)
          send_data(exporter.export!, filename: zip_filename)
        end
      end
    end

    def running
      @questions = generator.questions.keys
      @contents = @report&.completed_questions
      @path_for_running = path_for_running_question
    end

    def history
      @questions = generator.questions.keys
      @contents = @report&.completed_questions
      @path_for_running = path_for_running_question
    end

    def new
    end

    def create
      if @filter.valid?
        @report = report_source.from_filter(@filter, report_name, build_for_questions: generator.questions.keys)
        generator.new(@report).queue
        redirect_to(path_for_history(filter: @filter.to_h))
      else
        render :new
      end
    end

    def destroy
      @report.destroy
      flash[:notice] = 'Report removed'
      redirect_to(path_for_history)
    end

    def download
      respond_to do |format|
        format.html {}
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=#{generator.file_prefix} - #{DateTime.current.to_s(:db)}.xlsx"
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
      @report_urls ||= Rails.application.config.hud_reports.values.map { |report| [report[:title], public_send(report[:helper])] }.uniq
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

    private def filter
      year = if Date.current.month >= 10
        Date.current.year
      else
        Date.current.year - 1
      end
      # Some sane defaults, using the previous report if available
      @filter = filter_class.new(user_id: current_user.id, enforce_one_year_range: false)
      if filter_params.blank?
        prior_report = generator.find_report(current_user)
        options = prior_report&.options
        site_coc_codes = GrdaWarehouse::Config.get(:site_coc_codes).presence&.split(/,\s*/)
        if options.present?
          @filter.start = options['start'].presence || Date.new(year - 1, 10, 1)
          @filter.end = options['end'].presence || Date.new(year, 9, 30)
          @filter.coc_codes = options['coc_codes'].presence || site_coc_codes
          @filter.update(options.with_indifferent_access)
          @filter.report_version = options['report_version'].presence || default_report_version
        else
          @filter.start = Date.new(year - 1, 10, 1)
          @filter.end = Date.new(year, 9, 30)
          @filter.coc_codes = site_coc_codes
          @filter.report_version = default_report_version
        end
      end
      # Override with params if set
      @filter.update(filter_params) if filter_params.present?
    end

    def filter_params
      return {} unless params[:filter]

      filter_p = params.require(:filter).permit(filter_class.new.known_params)
      filter_p[:user_id] = current_user.id
      filter_p[:enforce_one_year_range] = false
      # filter[:project_ids] = filter[:project_ids].reject(&:blank?).map(&:to_i)
      # filter[:project_group_ids] = filter[:project_group_ids].reject(&:blank?).map(&:to_i)
      filter_p
    end

    private def zip_filename
      "#{generator.file_prefix} - #{DateTime.current.to_s(:db)}.zip"
    end

    private def report_scope
      report_source.where(report_name: possible_titles)
    end

    private def possible_titles
      possible_generator_classes.map(&:title)
    end

    def report_version_urls
      available_report_versions.map do |year, slug|
        [
          "#{generator.short_name} #{year}",
          slug,
        ]
      end
    end
    helper_method :report_version_urls

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
