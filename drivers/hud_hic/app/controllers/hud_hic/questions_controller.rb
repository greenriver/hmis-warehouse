###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudHic
  class QuestionsController < HicsController
    before_action :set_report, only: [:result]
    before_action :set_question
    before_action :set_reports

    private def report_param_name
      :hic_id
    end

    def result
    end

    private def set_question
      @question = generator.valid_question_number(params[:id])
    end
  end
end
