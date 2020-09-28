###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr
  class CapersController < BaseController
    include Caper::CaperConcern
    before_action -> { set_generator(param_name: :generator) }, except: [:index, :running_all_questions]
    before_action -> { set_report(param_name: :id) }, only: [:show, :edit, :destroy, :running]
    before_action :set_reports, except: [:index, :running_all_questions]
    before_action :filter

    def index
      @tab_content_reports = Report.active.order(weight: :asc, type: :desc).map(&:report_group_name).uniq
      @report_urls = report_urls
      @generators = generators
      @path_for_running = running_all_questions_hud_reports_capers_path
      @report_
    end

    def running_all_questions
      index
    end

    def show
      respond_to do |format|
        format.html do
          @show_recent = params[:id].to_i.positive?
          @questions = @generator.questions.keys
          @contents = @report&.completed_questions
          @path_for_running = running_hud_reports_capers_path(link_params.except('action', 'controller'))
        end
        format.zip do
          exporter = HudReports::ZipExporter.new(@report)
          date = Date.current.strftime('%Y-%m-%d')
          send_data(exporter.export!, filename: "caper-#{date}.zip")
        end
      end
    end

    def running
      @questions = @generator.questions.keys
      @contents = @report&.completed_questions
      @path_for_running = running_hud_reports_capers_path(link_params.except('action', 'controller'))
    end

    def edit
    end

    def update
      gen = @generator.new(@filter)
      gen.run!
      redirect_to hud_reports_caper_path(0, generator: @generator_id)
    end

    def destroy
      @report.destroy
      flash[:notice] = 'Report removed'
      redirect_to hud_reports_caper_path(0, generator: @generator_id)
    end
  end
end
