###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  module Concerns
    # Auth-agnostic bulk of the inactive-user (reactivation) surface, shared by the Devise arm
    # (Admin::InactiveUsersController) and the JWT arm (Admin::Idp::InactiveUsersController).
    # Each arm defines its own #reactivate — the only auth-coupled action here.
    module InactiveUserManagementBehavior
      extend ActiveSupport::Concern

      included do
        include ViewableEntities # TODO: START_ACL remove when ACL transition complete
        before_action :require_can_edit_users!
      end

      def index
        # Preload :legacy_roles — the index view renders the legacy-role names, not :roles.
        @users = user_scope.preload(:roles, :legacy_roles)
        @pagy, @users = pagy(@users)
      end

      def search
        search_query = GrdaWarehouse::ClientSearchQuery.find_by(id: params[:id])
        return handle_invalid_query('Search query not found') if search_query.nil?

        search_query.touch
        perform_search(search_query.query_params)
      end

      def title_for_index
        'User List'
      end

      private def user_scope
        User.inactive
      end

      private def perform_search(search_params = {})
        @query = search_params['q'].presence
        if @query
          @users = user_scope.text_search(@query)
        else
          @users = user_scope.none
        end

        @pagy, @users = pagy(@users.preload(:roles, :legacy_roles))
        render :index
      end

      private def handle_invalid_query(message)
        flash[:error] = message
        redirect_to admin_inactive_users_path
      end
    end
  end
end
