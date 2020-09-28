###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Caper
  class QuestionsController < HudApr::QuestionsController
    include CaperConcern

    def show
      @path_for_running = running_hud_reports_caper_question_path(link_params.except('action', 'controller'))
    end
  end
end
