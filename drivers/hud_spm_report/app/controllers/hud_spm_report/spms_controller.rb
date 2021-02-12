###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport
  class SpmsController < BaseController
    def index
      @tab_content_reports = Report.active.order(weight: :asc, type: :desc).map(&:report_group_name).uniq
      @report_urls = report_urls
    end

    def show
    end

    def running
      @questions = generator.questions.keys
      @contents = @report&.completed_questions
      @path_for_running = running_hud_reports_smps_path(link_params.except('action', 'controller'))
    end

    def new
    end

    def create
      if @filter.valid?
        @report = report_source.from_filter(@filter, report_name, build_for_questions: generator.questions.keys)
        generator.new(@report).queue
        redirect_to hud_reports_spm_path(0)
      else
        render :new
      end
    end

    def destroy
      @report.destroy
      flash[:notice] = 'Report removed'
      redirect_to hud_reports_spm_path(0)
    end
  end
end
