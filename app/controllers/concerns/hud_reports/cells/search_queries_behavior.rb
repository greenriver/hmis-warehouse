###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudReports
  module Cells
    # Subclasses must implement:
    # - report_param_name
    # - set_report
    # - generator (must be available via method or before_action)
    # - build_search_path(query_id)
    # - build_cell_path
    module SearchQueriesBehavior
      extend ActiveSupport::Concern

      def create
        set_report
        set_cell_params

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

      def set_cell_params
        @question = generator.valid_question_number(params[:measure_id] || params[:question_id])
        @cell = @report.valid_cell_name(params.require(:cell_id))
        @table = params.require(:table)
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
