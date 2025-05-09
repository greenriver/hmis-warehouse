# frozen_string_literal: true

module Clients
  class SearchQueriesController < ApplicationController
    before_action :require_can_access_some_client_search!

    def create
      safe_params = GrdaWarehouse::ClientSearchQuery.permit_params(params)
      query = GrdaWarehouse::ClientSearchQuery.find_or_create_by_params!(safe_params, user: current_user)
      redirect_to client_search_query_path(id: query.id)
    end

    protected

    def search_query_scope
      current_user.client_search_queries
    end
  end
end
