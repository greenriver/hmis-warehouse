###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Caper
  class QuestionsController < HudApr::QuestionsController
    include CaperConcern
    before_action :set_report, only: [:show, :destroy, :running, :result]
    before_action :set_question
    before_action :set_reports

    private def report_param_name
      :caper_id
    end

    def show
      @path_for_running = running_hud_reports_caper_question_path(link_params.except('action', 'controller'))
    end
  end
end
