###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudReports
  # Subclasses must implement:
  # - report_param_name (e.g., :spm_id, :apr_id)
  # - export_class_name (e.g., 'HudSpmReport::DocumentExports::CellDetailExport')
  # - export_job_class
  # - fallback_path
  # - path_for_cell_without_search
  # - path_for_search_queries
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

    def render_html_response(scope, filtered: false)
      @filtered_count = scope.count
      @total_count = filtered ? base_scope.count : @filtered_count

      scope = preload_associations(scope)
      @pagy, @clients = pagy(scope, items: 100)

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
