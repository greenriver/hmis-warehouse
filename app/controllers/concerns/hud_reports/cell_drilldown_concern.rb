###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudReports
  # This Concern provides standardized behavior for HUD report cell drill-down views.
  # It handles HTML display with pagination and XLSX export coordination.
  #
  # Subclasses must implement:
  # - report_param_name: The key in `params` identifying the report (e.g., `:spm_id`)
  # - export_class_name: The string name of the DocumentExport class for this report
  # - export_job_class: The class of the ActiveJob that runs the export
  # - export_query_params: Hash of parameters required by the export job
  # - fallback_path: Path to redirect to after an export is queued
  # - path_for_cell_without_search: Path to the cell view without search parameters
  # - preload_associations(scope): (Optional) Preload associations for the client scope
  #
  # The including controller must also provide or inherit:
  # - set_report: Sets `@report`
  # - generator: Returns the report generator instance
  #
  # This concern sets the following instance variables in `set_cell_variables`:
  # - @question: The validated question/measure identifier
  # - @cell: The validated cell identifier
  # - @table: The validated table identifier
  # - @name: The display name for the drill-down (via `build_drilldown_name`)
  # - @headers: The column headers for the results table
  module CellDrilldownConcern
    extend ActiveSupport::Concern

    included do
      rescue_from ActionController::ParameterMissing do |_exception|
        # the `table` param is required but can get lost when a user's session expires
        # TODO: make table_id part of the path, not a param
        redirect_to root_path, alert: 'The requested information could not be loaded'
      end
    end


    def show
      set_cell_variables
      @search_term = nil
      @searchable = model_searchable?

      respond_to do |format|
        format.html { render_html_response(base_scope, filtered: false) }
        format.xlsx { render_xlsx_response }
      end
    end

    def search
      set_cell_variables

      search_query = GrdaWarehouse::ClientSearchQuery.find_by(id: params[:query_id])
      return handle_invalid_query('Search query not found') if search_query.nil?

      search_query.touch
      @search_term = search_query.query_params[:q].to_s

      @searchable = model_searchable?
      filtered_scope = @searchable ? base_scope.model.search_clients(base_scope, @search_term) : base_scope

      respond_to do |format|
        format.html { render_html_response(filtered_scope, filtered: @searchable && @search_term.present?) }
      end
    end

    private
    def set_cell_variables
      params.require(report_param_name)
      set_report

      @question = generator.valid_question_number(params[:measure_id] || params[:question_id] || params[:question])
      @cell = @report.valid_cell_name(params.require(:id))
      @table = @report.valid_table_name(params.require(:table))
      @name = build_drilldown_name
      @headers = drilldown_headers
    end

    def drilldown_headers
      generator.column_headings(@question)
    end

    def base_scope
      client_scope_for_question.
        joins(hud_reports_universe_members: { report_cell: :report_instance }).
        merge(::HudReports::ReportCell.for_table(@table).for_cell(@cell)).
        merge(::HudReports::ReportInstance.where(id: @report.id)).
        distinct
    end

    def client_scope_for_question
      generator.client_scope(@question)
    end

    def model_searchable?
      base_scope.model.respond_to?(:searchable?) && base_scope.model.searchable?
    end

    def pagination_limit
      100
    end

    def render_html_response(scope, filtered: false)
      @filtered_count = scope.count
      @total_count = filtered ? base_scope.count : @filtered_count

      scope = preload_associations(scope)
      @pagy, @clients = pagy(scope, items: pagination_limit)

      # Preload only for the current page
      project_ids = @clients.map(&:project_id).compact.uniq
      current_user.policy_context.preload_project_dependencies(project_ids) if project_ids.any?

      render :show
    end

    def preload_associations(scope)
      # Override in subclass if needed
      scope
    end

    def render_xlsx_response
      export = current_user.document_exports.create!(
        type: export_class_name,
        status: DocumentExportBehavior::PENDING_STATUS,
        query_string: export_query_params.to_query,
      )

      export_job_class.perform_later(export_id: export.id)

      flash[:notice] = 'Your cell-detail export is being generated. You will receive an email with a download link shortly.'
      redirect_back(fallback_location: fallback_path)
    end

    def export_query_params
      # Subclasses must implement
      raise NotImplementedError
    end

    def export_job_class
      # Subclasses must implement
      raise NotImplementedError
    end

    def export_class_name
      # Subclasses must implement
      raise NotImplementedError
    end

    def fallback_path
      # Subclasses must implement
      raise NotImplementedError
    end

    def handle_invalid_query(message)
      flash[:error] = message
      redirect_to path_for_cell_without_search
    end

    def path_for_cell_without_search
      # Subclasses must implement
      raise NotImplementedError
    end

    def build_drilldown_name
      @report.drilldown_name(
        question: @question,
        table: @table,
        cell: @cell,
        prefix: generator.file_prefix,
      )
    end
  end
end
