###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr
  class BaseController < ::HudReports::BaseController
    before_action :filter

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

    def available_report_versions
      {
        'FY 2020' => :fy2020,
        'FY 2021' => :fy2021,
      }.freeze
    end
    helper_method :available_report_versions

    def default_report_version
      :fy2020
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

    def filter_params
      return {} unless params[:filter]

      filter_p = params.require(:filter).permit(filter_class.new.known_params)
      filter_p[:user_id] = current_user.id
      filter_p[:enforce_one_year_range] = false
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

    private def filter_class
      ::Filters::HudFilterBase
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
  end
end
