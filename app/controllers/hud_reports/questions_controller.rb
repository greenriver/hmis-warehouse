###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudReports
  class QuestionsController < ApplicationController
    before_action :set_generator
    before_action :set_report

    def show
      @question = params[:id]
      options = @report&.options || {}
      @options = OpenStruct.new(
        start_date: options['start_date']&.to_date || Date.current.beginning_of_month,
        end_date: options['end_date']&.to_date || Date.current.end_of_month,
        coc_code: options['coc_code'],
        project_ids: options['project_ids']&.map(&:to_i),
      )
    end

    def update
      gen = @generator.new(filter_options)
      question = params[:id]
      gen.run!(questions: [question])
      redirect_to hud_reports_apr_question_path(@generator_id, question)
    end

    def filter_options
      filter = params.require(:filter).
        permit(
          :start_date,
          :end_date,
          :coc_code,
          project_ids: [],
        )
      filter[:user_id] = current_user.id
      filter[:project_ids] = filter[:project_ids].reject(&:blank?).map(&:to_i)
      filter
    end

    def set_generator
      @generator_id = params[:id].to_i
      @generator = generators[@generator_id]
    end

    def set_report
      report_id = params[:apr_id].to_i
      # APR 0 is the most recent report for the current user
      if report_id.zero?
        @report = @generator.find_report(current_user)
      else
        @report = report_source.find(report_id)
      end
    end

    def generators
      [
        ReportGenerators::Apr::Fy2020::Generator,
      ]
    end

    def report_source
      HudReports::ReportInstance
    end
  end
end
