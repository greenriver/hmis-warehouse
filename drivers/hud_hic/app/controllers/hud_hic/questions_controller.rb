###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudHic
  class QuestionsController < HicsController
    before_action :set_report, only: [:show, :destroy, :running, :result]
    before_action :set_question
    before_action :set_reports

    private def report_param_name
      :hic_id
    end

    def running
    end

    def result
    end

    def show
      @filter.default_project_type_codes = generator.default_project_type_codes
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
