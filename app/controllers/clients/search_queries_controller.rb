# frozen_string_literal: true

module Clients
  # This controller is responsible for securely storing client search parameters
  class SearchQueriesController < ApplicationController
    before_action :require_can_access_some_client_search!

    def create
      safe_params = GrdaWarehouse::ClientSearchQuery.permit_params(params)
      query = GrdaWarehouse::ClientSearchQuery.find_or_create_by_params(safe_params, user: current_user)
      if query.valid?
        redirect_to client_search_query_path(id: query.encrypted_id)
      else
        flash[:error] = 'Search query not valid'
        redirect_to clients_path
        return
      end
    end
  end
end
