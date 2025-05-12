###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class EditHistoriesController < ::ApplicationController
    before_action :require_can_audit_users!
    before_action :set_user

    def show
      @history = UserEditHistory::Versions.new(@user)
    end

    private

    # The user record we are viewing the history of
    def set_user
      @user_id = params[:user_id].to_i
      @user = User.find(@user_id)
    end
  end
end
