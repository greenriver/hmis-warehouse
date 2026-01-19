###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudReports
  module Cells
    # This Concern provides standardized behavior for creating and redirecting client search queries
    # within the context of a HUD report cell.
    #
    # The including class must provide the following interface:
    #
    # @method report_param_name
    #   @return [Symbol] the key in `params` identifying the report instance (e.g., `:apr_id`, `:spm_id`)
    #
    # @method question_param_name
    #   @return [Symbol] the key in `params` identifying the question or measure (e.g., `:question_id`, `:measure_id`)
    #
    # @method set_report
    #   Fetches and sets the `@report` instance. Usually provided by `HudReports::BaseController`.
    #
    # @method generator
    #   @return [Class, Object] the report generator instance or class used for question validation.
    #   Usually provided by `HudReports::BaseController`.
    #
    # @method build_search_path(query_id)
    #   @param query_id [String, Integer] the ID of the persistent search query.
    #   @return [String] the URL for the search results view.
    #
    # @method build_cell_path
    #   @return [String] the URL for the cell details view (used for error fallbacks).
    module SearchQueriesBehavior
      extend ActiveSupport::Concern

      def create
        set_report

        @drilldown = generator.drilldown_context(
          report: @report,
          measure_id: params.require(question_param_name),
          cell_id: params.require(:cell_id),
          table_id: params.require(:table),
        )

        safe_params = GrdaWarehouse::ClientSearchQuery.permit_params(params)
        query = GrdaWarehouse::ClientSearchQuery.find_or_create_by_params(safe_params, user: current_user)

        if query.valid?
          redirect_to build_search_path(query.id)
        else
          flash[:error] = 'Search query not valid'
          redirect_to build_cell_path
        end
      end

      private

      def report_param_name
        # Subclasses must implement
        raise NotImplementedError
      end

      def question_param_name
        # Subclasses must implement
        raise NotImplementedError
      end

      def build_search_path(query_id)
        # Subclasses must implement
        raise NotImplementedError
      end

      def build_cell_path
        # Subclasses must implement
        raise NotImplementedError
      end
    end
  end
end
