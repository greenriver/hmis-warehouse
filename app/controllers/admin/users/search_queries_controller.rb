###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin::Users
  # This controller is responsible for securely storing user search parameters
  class SearchQueriesController < ApplicationController
    before_action :require_can_edit_users!

    def create
      safe_params = GrdaWarehouse::ClientSearchQuery.permit_params(params)
      query = GrdaWarehouse::ClientSearchQuery.find_or_create_by_params(safe_params, user: current_user)
      if query.valid?
        redirect_to user_search_query_admin_users_path(id: query.id)
      else
        flash[:error] = 'Search query not valid'
        redirect_to admin_users_path
        return
      end
    end
  end
end
