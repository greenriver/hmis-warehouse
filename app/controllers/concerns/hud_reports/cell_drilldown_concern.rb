###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudReports
  # This Concern provides standardized behavior for HUD report cell drill-down views.
  # It handles HTML display with pagination.
  #
  # Subclasses must implement:
  # - report_param_name: The key in `params` identifying the report (e.g., `:spm_id`)
  # - measure_id: The identifier for the question or measure being viewed
  # - export_class_name: The string name of the DocumentExport class for this report
  # - export_query_params: Hash of parameters required by the export job
  # - path_for_cell_without_search: Path to the cell view without search parameters
  # - preload_associations(scope): (Optional) Preload associations for the client scope
  # - drilldown_report_type: (Optional) The specific type of report (e.g., 'apr')
  #
  # The including controller must also provide or inherit:
  # - set_report: Sets `@report`
  # - generator: Returns the report generator instance
  #
  # This concern sets the `@drilldown` instance variable (a HudReports::DrilldownContext).
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
      set_drilldown_context
      @drilldown.search_term = nil

      respond_to do |format|
        format.html { render_html_response(@drilldown.base_scope) }
      end
    end

    def search
      set_drilldown_context

      search_query = GrdaWarehouse::ClientSearchQuery.find_by(id: params[:query_id])
      return handle_invalid_query('Search query not found') if search_query.nil?

      search_query.touch
      @drilldown.apply_search_query!(search_query)

      respond_to do |format|
        format.html { render_html_response(@drilldown.filtered_scope) }
      end
    end

    private

    def set_drilldown_context
      params.require(report_param_name)
      set_report

      @drilldown = generator.drilldown_context(
        report: @report,
        measure_id: measure_id,
        cell_id: params.require(:id),
        table_id: params.require(:table),
        report_type: drilldown_report_type,
      )
    end

    def measure_id
      # Subclasses must implement
      raise NotImplementedError
    end

    def drilldown_report_type
      nil # Optional - override in subclass if needed
    end

    def pagination_limit
      100
    end

    def render_html_response(scope)
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

    def export_query_params
      # Subclasses must implement
      raise NotImplementedError
    end

    def export_class_name
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
