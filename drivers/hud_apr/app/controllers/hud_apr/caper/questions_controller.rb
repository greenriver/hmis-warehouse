###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Caper
  class QuestionsController < HudApr::QuestionsController
    include CaperConcern
    before_action :set_report, only: [:show, :destroy, :running, :result]
    before_action :set_question
    before_action :set_reports

    def set_report
      report_id = params[:caper_id].to_i
      return if report_id.zero?

      @report = if can_view_all_hud_reports?
        report_scope.find(report_id)
      else
        report_scope.where(user_id: current_user.id).find(report_id)
      end
    end

    def show
      @path_for_running = running_hud_reports_caper_question_path(link_params.except('action', 'controller'))
    end
  end
end
