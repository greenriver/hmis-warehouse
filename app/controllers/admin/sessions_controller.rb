###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  class SessionsController < ApplicationController
    before_action :require_can_manage_sessions!

    def index
      @users = User.has_recent_activity
    end

    def destroy
      user = User.find(params[:id])
      session_id = user.unique_session_id

      if session_id.present?
        # Add the user's current subject (sub claim) to the denylist
        # Set expiration to 12 hours (same as default OAuth2-proxy session timeout)
        TokenDenylist.add(session_id, expires_at: Time.current + 12.hours)
      end

      redirect_to(
        { action: :index },
        notice: "Session ended for #{user.name}. They will be forced to sign in again on their next request."
      )
    end
  end
end
