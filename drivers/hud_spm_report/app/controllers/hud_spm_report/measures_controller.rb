###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport
  class MeasuresController < BaseController
    before_action :set_report, only: [:show, :destroy, :running, :result]
    before_action :set_question
    before_action :set_reports

    private def report_param_name
      :spm_id
    end

    def running
    end

    def result
    end

    def show
      @path_for_running = running_hud_reports_spm_measure_path(link_params.except('action', 'controller'))
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
  end
end
