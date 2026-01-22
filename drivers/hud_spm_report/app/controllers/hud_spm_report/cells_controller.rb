###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudSpmReport
  # Controller for SPM report cell drill-down views.
  # Most behavior is inherited from HudReports::CellDrilldownConcern.
  class CellsController < HudSpmReport::BaseController
    include ::HudReports::CellDrilldownConcern

    private def report_param_name
      :spm_id
    end

    private def measure_id
      params.require(:measure_id)
    end

    private def preload_associations(scope)
      scope.preload(client: [:data_source, :source_clients])
    end

    private def export_class_name
      'HudSpmReport::DocumentExports::CellDetailExport'
    end

    private def export_query_params
      @drilldown.query_params.merge(report_id: @drilldown.report.id)
    end

    private def path_for_cell_without_search
      hud_reports_spm_measure_cell_path(
        spm_id: @drilldown.report.id,
        measure_id: @drilldown.measure,
        id: @drilldown.cell,
        table: @drilldown.table,
      )
    end

    private def path_for_search_queries
      hud_reports_spm_measure_cell_search_queries_path(
        spm_id: @drilldown.report.id,
        measure_id: @drilldown.measure,
        cell_id: @drilldown.cell,
        table: @drilldown.table,
      )
    end
  end
end
