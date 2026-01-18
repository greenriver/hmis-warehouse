###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::CeApr::Cells
  class SearchQueriesController < ::HudApr::BaseController
    include ::HudApr::CeApr::CeAprConcern
    include ::HudReports::Cells::SearchQueriesBehavior

    private def report_param_name
      :ce_apr_id
    end

    private def build_search_path(query_id)
      search_hud_reports_ce_apr_question_cell_path(
        ce_apr_id: @report.id,
        question_id: @question,
        id: @cell,
        query_id: query_id,
        table: @table,
      )
    end

    private def build_cell_path
      hud_reports_ce_apr_question_cell_path(
        ce_apr_id: @report.id,
        question_id: @question,
        id: @cell,
        table: @table,
      )
    end
  end
end
