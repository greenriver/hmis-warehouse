###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  class InactiveUsersController < ApplicationController
    include ViewableEntities # TODO: START_ACL remove when ACL transition complete
    # This controller is namespaced to prevent
    # route collision with Devise
    before_action :require_can_edit_users!

    require 'active_support'
    require 'active_support/core_ext/string/inflections'

    def index
      @users = user_scope.preload(:roles)
      @pagy, @users = pagy(@users)
    end

    def search
      search_query = GrdaWarehouse::ClientSearchQuery.find_by(id: params[:id])
      return handle_invalid_query('Search query not found') if search_query.nil?

      search_query.touch
      perform_search(search_query.query_params)
    end

    def reactivate
      @user = User.inactive.find(params[:id].to_i)
      pass = Devise.friendly_token(50)
      @user.update(
        active: true,
        last_activity_at: Time.current,
        expired_at: nil,
        password: pass,
        password_confirmation: pass,
      )

      # FIXME(#186770279): shouldn't send for oauth-linked accounts
      @user.send_reset_password_instructions
      redirect_to({ action: :index }, notice: "User #{@user.name} re-activated")
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

      @pagy, @users = pagy(@users.preload(:roles))
      render :index
    end

    private def handle_invalid_query(message)
      flash[:error] = message
      redirect_to admin_inactive_users_path
    end
  end
end
