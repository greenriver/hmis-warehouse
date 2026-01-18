###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr
  class CellsController < HudApr::QuestionsController
    include ::HudReports::CellDrilldownConcern
    include ApplicationHelper
    include ActionView::Helpers::TagHelper

    helper_method :export_class_name, :export_query_params,
                  :path_for_search_queries, :path_for_cell_without_search

    private def set_question
      @question = generator.valid_question_number(params[:question] || params[:question_id])
    end

    private def set_cell_variables
      set_question
      @cell = @report.valid_cell_name(params.require(:id))
      @table = @report.valid_table_name(params.require(:table))
      @name = "#{generator.file_prefix} #{@question} #{@table} #{@cell}"
      @headers = generator.client_class(@question).detail_headers
    end

    private def base_scope
      generator.client_class(@question).
        joins(hud_reports_universe_members: { report_cell: :report_instance }).
        merge(::HudReports::ReportCell.for_table(@table).for_cell(@cell)).
        merge(::HudReports::ReportInstance.where(id: @report.id)).
        distinct
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
