###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Dq
  class QuestionsController < HudApr::QuestionsController
    include DqConcern
    before_action :set_report, only: [:show, :destroy, :running, :result]
    before_action :set_question
    before_action :set_reports

    private def report_param_name
      :dq_id
    end
  end
end
