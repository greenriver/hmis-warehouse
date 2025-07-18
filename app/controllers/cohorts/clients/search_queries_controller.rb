###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Cohorts::Clients
  # This controller is responsible for securely storing cohort client search parameters
  class SearchQueriesController < ApplicationController
    before_action :require_can_access_some_client_search!

    def create
      safe_params = GrdaWarehouse::ClientSearchQuery.permit_params(params)
      query = GrdaWarehouse::ClientSearchQuery.find_or_create_by_params(safe_params, user: current_user)
      if query.valid?
        redirect_to cohort_cohort_client_search_query_path(id: query.id)
      else
        flash[:error] = 'Search query not valid'
        redirect_to new_cohort_cohort_client_path
        return
      end
    end
  end
end
