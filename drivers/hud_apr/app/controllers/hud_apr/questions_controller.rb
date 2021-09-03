###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr
  class QuestionsController < BaseController
    def running
    end

    def result
    end

    def create
      question = params[:question]
      @report = report_source.from_filter(@filter, report_name, build_for_questions: [question])
      generator.new(@report).queue
      redirect_to(path_for_history(filter: @filter.to_h))
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
  end
end
