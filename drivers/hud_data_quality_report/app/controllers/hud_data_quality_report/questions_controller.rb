###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudDataQualityReport
  class QuestionsController < BaseController
    before_action :set_report, only: [:show, :destroy, :running, :result]
    before_action :set_question
    before_action :set_reports

    def running
    end

    def result
    end

    def show
      @path_for_running = running_hud_reports_dq_question_path(link_params.except('action', 'controller'))
    end

    def create
      question = params[:question]
      @report = report_source.from_filter(@filter, report_name, build_for_questions: [question])
      generator.new(@report).queue
      redirect_to path_for_report(0)
    end

    private def set_question
      @question = generator.valid_question_number(params[:question] || params[:id])
    end

    private def set_reports
      @reports = report_scope.joins(:report_cells).
        preload(:universe_cells).
        merge(report_cell_source.universe.where(question: @question))
      @reports = @reports.where(user_id: current_user.id) unless can_view_all_hud_reports?
      @reports = @reports.order(created_at: :desc).
        page(params[:page]).per(10)
    end

    private def report_param_name
      :dq_id
    end
  end
end
