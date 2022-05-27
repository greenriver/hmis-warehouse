###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport
  class QuestionsController < BaseController
    before_action :set_report, only: [:show, :destroy, :running, :result]
    before_action :set_question
    before_action :set_reports

    def running
    end

    def result
    end

    def show
      @path_for_running = running_hud_reports_path_question_path(link_params.except('action', 'controller'))
    end

    def create
      question = params[:question]
      @report = report_source.from_filter(@filter, report_name, build_for_questions: [question])
      generator.new(@report).queue
      redirect_to history_hud_reports_paths_path
    end

    private def set_question
      @question = generator.valid_question_number(params[:question_id] || params[:id])
    end

    private def report_param_name
      :path_id
    end
  end
end
