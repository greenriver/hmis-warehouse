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
      # Subclasses must override with specific report path
      raise NotImplementedError
    end

    private def path_for_cell_without_search
      # Subclasses must override with specific cell path
      raise NotImplementedError
    end
  end
end
