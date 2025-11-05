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
  end
end
