###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class SessionsController < ApplicationController
    before_action :require_can_manage_sessions!

    def index
      @users = User.has_recent_activity
    end

    def destroy
      user = User.find(params[:id])
      user.unique_session_id = nil
      user.save
      redirect_to({ action: :index }, notice: "Session ended for #{user.name}")
    end
  end
end
