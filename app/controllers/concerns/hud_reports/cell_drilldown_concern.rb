###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudReports
  # Subclasses must implement:
  # - base_scope: Returns the ActiveRecord relation of clients for the cell
  # - export_class_name (e.g., 'HudSpmReport::DocumentExports::CellDetailExport')
  # - export_job_class
  # - export_query_params: Hash of params for the export job
  # - fallback_path: Redirect location after XLSX export is queued
  # - path_for_cell_without_search: Redirect location for invalid search queries
  # - path_for_search_queries: Helper method used in views for the search form
  #
  # Subclasses must set these instance variables in `set_cell_variables`:
  # - @report: The report instance (required for crumbs and search forms)
  # - @generator: The report's generator instance
  # - @question or @measure_id: The specific report question/measure being viewed
  # - @cell: The specific cell identifier
  # - @table: The specific table identifier
  # - @name: The display name for the drill-down
  # - @headers: Array of column headers for the display table
  module CellDrilldownConcern
    extend ActiveSupport::Concern

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
      # Subclasses should call super or implement themselves
      # Expected variables: @question or @measure_id, @cell, @table, @name, @headers
    end

    def base_scope
      # Subclasses must implement
      raise NotImplementedError
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
  end
end
