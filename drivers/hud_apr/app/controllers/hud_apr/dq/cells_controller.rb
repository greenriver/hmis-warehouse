###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Dq
  class CellsController < HudApr::CellsController
    include DqConcern
    before_action :set_report
    before_action :set_question

    def report_param_name
      :dq_id
    end

    private def report_type_param
      'dq'
    end

    private def fallback_path
      hud_reports_dq_path(@report)
    end

    private def path_for_cell_without_search
      hud_reports_dq_question_cell_path(
        dq_id: @report.id,
        question_id: @question,
        id: @cell,
        table: @table,
      )
    end

    private def path_for_search_queries
      hud_reports_dq_question_cell_search_queries_path(
        dq_id: @report.id,
        question_id: @question,
        cell_id: @cell,
        table: @table,
      )
    end
  end
end
