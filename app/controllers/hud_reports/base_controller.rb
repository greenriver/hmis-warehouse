###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudReports
  class BaseController < ApplicationController
    before_action :require_can_view_hud_reports!
    before_action :set_view_filter, only: [:history, :show, :running]

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
      return [] if generator.blank?

      title = generator.title
      @reports = report_scope.where(report_name: title).
        preload(:user, :universe_cells)
      if @question.present?
        @reports = @reports.joins(:report_cells).
          merge(report_cell_source.universe.where(question: @question))
      end
      @reports = apply_view_filters(@reports)
      @reports = @reports.order(created_at: :desc).
        page(params[:page]).per(25)
    end

    def apply_view_filters(reports)
      if can_view_all_hud_reports?
        # Only apply a user filter if you have chosen one if you can see all reports
        reports = reports.where(user_id: @view_filter[:creator]) if @view_filter.try(:[], :creator).present? && @view_filter[:creator] != 'all'
      else
        reports = reports.where(user_id: current_user.id)
      end
      return reports unless @view_filter.present?

      reports = if @view_filter.try(:[], :run_type) == 'automated'
        reports.automated
      else
        reports.manual
      end

      filter_range = Time.zone.parse(@view_filter[:start]) .. (Time.zone.parse(@view_filter[:end]) + 1.days)
      reports.where(created_at: filter_range)
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
      # Force a re-calculation of generator if we have a report so we get the appropriate year
      @generator = nil
      generator
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
        :run_type,
        :creator,
        :start,
        :end,
        filter: [
          :report_version,
        ],
      )
    end

    private def set_view_filter
      defaults = {
        run_type: 'manual',
        creator: 'all',
        start: (Date.current - 6.months).to_s,
        end: Date.current.to_s,
      }
      @view_filter = {}
      @view_filter[:run_type] = view_filter_params[:run_type] || defaults[:run_type]
      @view_filter[:creator] = view_filter_params[:creator] || defaults[:creator]
      @view_filter[:start] = view_filter_params[:start] || defaults[:start]
      @view_filter[:end] = view_filter_params[:end] || defaults[:end]
      @active_filter = @view_filter != defaults
    end

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
      filter_p
    end

    private def zip_filename
      "#{generator.file_prefix} - #{DateTime.current.to_s(:db)}.zip"
    end

    private def report_scope
      report_source.where(report_name: possible_titles)
    end

    def generator
      @generator ||= possible_generator_classes[report_version]
    end
    helper_method :generator

    private def possible_titles
      possible_generator_classes.values.map(&:title)
    end

    def report_version_urls
      available_report_versions.map do |year, opts|
        [
          "#{generator.short_name} #{year}",
          opts[:slug],
        ]
      end
    end
    helper_method :report_version_urls

    def active_report_versions
      available_report_versions.map do |year, opts|
        next unless opts[:active]

        [
          "#{generator.short_name} #{year}",
          opts[:slug],
        ]
      end.compact
    end
    helper_method :active_report_versions

    private def default_report_version
      :fy2021
    end
    helper_method :default_report_version

    private def report_version
      version = filter_params[:report_version] ||
        @report&.options&.try(:[], 'report_version') ||
        @filter&.report_version ||
        link_params.try(:[], :filter).try(:[], :report_version) ||
        default_report_version
      version.to_sym
    end
    helper_method :report_version

    private def path_for_clear_view_filter
      args = report_version ? { filter: { report_version: report_version } } : {}
      if @question.present?
        path_for_question(@question, report: @report, args: args)
      else
        path_for_history(args)
      end
    end
    helper_method :path_for_clear_view_filter

    private def view_filter_available_users
      [['all', 'Any user']] + User.active.where(id: report_scope.pluck(:user_id)).map { |u| [u.id, u.name_with_email] }
    end
    helper_method :view_filter_available_users

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
