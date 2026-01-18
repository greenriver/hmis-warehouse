###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Apr
  class CellsController < HudApr::CellsController
    include AprConcern

    def report_param_name
      :apr_id
    end

    private def report_type_param
      'apr'
    end

    private def fallback_path
      hud_reports_apr_path(@report)
    end

    private def path_for_cell_without_search
      hud_reports_apr_question_cell_path(
        apr_id: @report.id,
        question_id: @question,
        id: @cell,
        table: @table,
      )
    end

    private def path_for_search_queries
      hud_reports_apr_question_cell_search_queries_path(
        apr_id: @report.id,
        question_id: @question,
        cell_id: @cell,
        table: @table,
      )
    end
  end
end
