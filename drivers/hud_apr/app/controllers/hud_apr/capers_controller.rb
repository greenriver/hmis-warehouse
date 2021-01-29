###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr
  class CapersController < BaseController
    include Caper::CaperConcern
    before_action :set_report, only: [:show, :destroy, :running]
    before_action :set_reports, except: [:index, :running_all_questions]

    def index
      @tab_content_reports = Report.active.order(weight: :asc, type: :desc).map(&:report_group_name).uniq
      @report_urls = report_urls
      @path_for_running = running_all_questions_hud_reports_capers_path
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
          @path_for_running = running_hud_reports_capers_path(link_params.except('action', 'controller'))
        end
        format.zip do
          exporter = ::HudReports::ZipExporter.new(@report)
          date = Date.current.strftime('%Y-%m-%d')
          send_data(exporter.export!, filename: "caper-#{date}.zip")
        end
      end
    end

    def running
      @questions = generator.questions.keys
      @contents = @report&.completed_questions
      @path_for_running = running_hud_reports_capers_path(link_params.except('action', 'controller'))
    end

    def edit
    end

    def create
      if @filter.valid?
        @report = report_source.from_filter(@filter, report_name, build_for_questions: generator.questions.keys)
        generator.new(@report).queue
        redirect_to hud_reports_caper_path(0)
      else
        render :new
      end
    end

    def destroy
      @report.destroy
      flash[:notice] = 'Report removed'
      redirect_to hud_reports_caper_path(0)
    end
  end
end
