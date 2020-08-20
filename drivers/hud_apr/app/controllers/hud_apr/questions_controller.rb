###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr
  class QuestionsController < BaseController
    before_action -> { set_generator(param_name: :id) }
    before_action -> { set_report(param_name: :apr_id) }

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
      redirect_to hud_reports_apr_path(0, generator: @generator_id)
    end
  end
end
