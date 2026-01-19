###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr
  # Base controller for APR, CAPER, CeAPR, and DQ report cell drill-down views.
  # Subclasses specify report-specific paths and identifiers.
  # Most behavior is inherited from HudReports::CellDrilldownConcern.
  class CellsController < HudApr::QuestionsController
    include ::HudReports::CellDrilldownConcern
    include ApplicationHelper
    include ActionView::Helpers::TagHelper

    helper_method :export_class_name, :export_query_params,
                  :path_for_search_queries, :path_for_cell_without_search

    def report_param_name
      :"#{report_type_param}_id"
    end

    private def base_scope
      super
    end

    private def preload_associations(scope)
      scope.preload(:data_source, source_enrollment: :client)
    end

    private def export_class_name
      'HudApr::DocumentExports::CellDetailExport'
    end

    private def export_job_class
      HudApr::CellDetailExportJob
    end

    private def export_query_params
      {
        report_id: @report.id,
        report_type: report_type_param,
        question: @question,
        cell_id: @cell,
        table: @table,
      }
    end

    private def report_type_param
      # Subclasses must override (e.g., 'apr', 'caper', 'ce_apr', 'dq')
      raise NotImplementedError
    end

    private def fallback_path
      public_send(:"hud_reports_#{report_type_param}_path", @report)
    end

    private def path_for_cell_without_search
      public_send(:"hud_reports_#{report_type_param}_question_cell_path",
                  report_param_name => @report.id,
                  question_id: @question,
                  id: @cell,
                  table: @table)
    end

    private def path_for_search_queries
      public_send(:"hud_reports_#{report_type_param}_question_cell_search_queries_path",
                  report_param_name => @report.id,
                  question_id: @question,
                  cell_id: @cell,
                  table: @table)
    end
  end
end
