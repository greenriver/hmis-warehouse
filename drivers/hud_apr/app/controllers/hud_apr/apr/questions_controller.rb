###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Apr
  class QuestionsController < HudApr::QuestionsController
    include AprConcern
    before_action :set_report, only: [:show, :destroy, :running, :result]
    before_action :set_question
    before_action :set_reports

    def report_param_name
      :apr_id
    end

    def show
      @path_for_running = running_hud_reports_apr_question_path(link_params.except('action', 'controller'))
    end
  end
end
