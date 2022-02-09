###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class InactiveUsersController < ApplicationController
    include ViewableEntities
    # This controller is namespaced to prevent
    # route collision with Devise
    before_action :require_can_edit_users!

    require 'active_support'
    require 'active_support/core_ext/string/inflections'

    def index
      # search
      @users = if params[:q].present?
        user_scope.text_search(params[:q])
      else
        user_scope
      end

      # sort / paginate
      @users = @users.
        preload(:roles).
        page(params[:page]).per(25)
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
      @user.send_reset_password_instructions
      redirect_to({ action: :index }, notice: "User #{@user.name} re-activated")
    end

    def title_for_index
      'User List'
    end

    private def user_scope
      User.inactive
    end
  end
end
