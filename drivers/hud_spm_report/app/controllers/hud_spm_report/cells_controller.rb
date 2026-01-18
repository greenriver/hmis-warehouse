###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudSpmReport
  class CellsController < HudSpmReport::BaseController
    include ::HudReports::CellDrilldownConcern

    private def report_param_name
      :spm_id
    end

    private def set_cell_variables
      params.require(report_param_name)
      set_report

      @question = generator.valid_question_number params.require(:measure_id)
      @cell = @report.valid_cell_name params.require(:id)
      @table = @report.valid_table_name params.require(:table)
      @name = build_drilldown_name
      @headers = generator.column_headings(@question)
    end

    private def base_scope
      generator.client_scope(@question).
        joins(hud_reports_universe_members: { report_cell: :report_instance }).
        merge(::HudReports::ReportCell.for_table(@table).for_cell(@cell)).
        merge(::HudReports::ReportInstance.where(id: @report.id)).
        distinct
    end

    private def preload_associations(scope)
      scope.preload(client: [:data_source, :source_clients])
    end

    private def export_class_name
      'HudSpmReport::DocumentExports::CellDetailExport'
    end

    private def export_job_class
      HudSpmReport::CellDetailExportJob
    end

    private def export_query_params
      {
        report_id: @report.id,
        measure_id: @question,
        cell_id: @cell,
        table: @table,
      }
    end

    private def fallback_path
      hud_reports_spm_path(@report)
    end

    private def path_for_cell_without_search
      hud_reports_spm_measure_cell_path(
        spm_id: @report.id,
        measure_id: @question,
        id: @cell,
        table: @table,
      )
    end

    private def path_for_search_queries
      hud_reports_spm_measure_cell_search_queries_path(
        spm_id: @report.id,
        measure_id: @question,
        cell_id: @cell,
        table: @table,
      )
    end
  end
end
