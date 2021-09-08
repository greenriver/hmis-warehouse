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

    def show
      @path_for_running = path_for_running_question
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
  end
end
