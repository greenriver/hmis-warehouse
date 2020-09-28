###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr
  class QuestionsController < BaseController
    before_action -> { set_generator(param_name: :id) }
    before_action -> { set_report(param_name: :apr_id) }
    before_action :set_question
    before_action :set_reports
    before_action :filter

    def running
    end

    def result
    end

    def update
      gen = @generator.new(filter_params)
      question = params[:id]
      gen.run!(questions: [question])
      redirect_to path_for_report(0, generator: @generator_id)
    end

    private def set_question
      @question = @generator.valid_question_number(params[:id])
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
