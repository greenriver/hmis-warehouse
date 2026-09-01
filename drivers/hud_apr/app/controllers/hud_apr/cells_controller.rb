###
# Copyright Green River Data Group, Inc.
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

    helper_method :drilldown_presenter_class

    def report_param_name
      :"#{report_type_param}_id"
    end

    private def measure_id
      params.require(:question_id)
    end

    private def drilldown_report_type
      report_type_param
    end

    private def preload_associations(scope)
      scope.preload(:data_source, source_enrollment: :client)
    end

    private def export_class_name
      'HudApr::DocumentExports::CellDetailExport'
    end

    private def export_query_params
      @drilldown.query_params.merge(report_id: @drilldown.report.id)
    end

    private def report_type_param
      raise NotImplementedError
    end

    private def path_for_cell_without_search
      public_send(:"hud_reports_#{report_type_param}_question_cell_path",
                  report_param_name => @drilldown.report.id,
                  question_id: @drilldown.measure,
                  id: @drilldown.cell,
                  table: @drilldown.table)
    end

    private def path_for_search_queries
      public_send(:"hud_reports_#{report_type_param}_question_cell_search_queries_path",
                  report_param_name => @drilldown.report.id,
                  question_id: @drilldown.measure,
                  cell_id: @drilldown.cell,
                  table: @drilldown.table)
    end

    def render_html_response(scope)
      scope = preload_associations(scope)
      @pagy, @clients = pagy(scope, items: pagination_limit)
      project_ids = @clients.map(&:project_id).compact.uniq
      current_user.policy_context.preload_project_dependencies(project_ids) if project_ids.any?
      render 'hud_apr/shared/cells/show'
    end

    private def drilldown_presenter_class
      HudApr::DrilldownPresenter
    end
  end
end
