# frozen_string_literal: true

module Clients
  class SearchQueriesController < ApplicationController
    before_action :require_can_access_some_client_search!

    def create
      query = search_query_scope.find_or_create_by_params!(safe_params)
      redirect_to client_search_query_path(id: query.id)
    end

    protected

    def search_query_scope
      current_user.client_search_queries
    end

    def safe_params
      params.permit(:q, client: [:first_name, :last_name, :dob, :ssn])
    end
  end
end
