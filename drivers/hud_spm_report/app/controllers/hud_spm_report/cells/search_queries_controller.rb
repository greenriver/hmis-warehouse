###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudSpmReport::Cells
  # This controller is responsible for securely storing SPM cell search parameters
  class SearchQueriesController < HudSpmReport::BaseController
    private def report_param_name
      :spm_id
    end

    def create
      set_report

      @question = generator.valid_question_number params.require(:measure_id)
      @cell = @report.valid_cell_name params.require(:cell_id)
      @table = params.require(:table)

      safe_params = GrdaWarehouse::ClientSearchQuery.permit_params(params)
      query = GrdaWarehouse::ClientSearchQuery.find_or_create_by_params(safe_params, user: current_user)

      if query.valid?
        redirect_to search_hud_reports_spm_measure_cell_path(
          spm_id: @report.id,
          measure_id: @question,
          id: @cell,
          query_id: query.id,
          table: @table,
        )
      else
        flash[:error] = 'Search query not valid'
        redirect_to hud_reports_spm_measure_cell_path(
          spm_id: @report.id,
          measure_id: @question,
          id: @cell,
          table: @table,
        )
      end
    end
  end
end
