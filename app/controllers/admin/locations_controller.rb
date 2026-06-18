###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  class LocationsController < ::ApplicationController
    before_action :require_can_audit_users!

    def show
      @user = User.find params[:user_id]
      @locations = @user.login_activities.order(created_at: :desc)
      @pagy, @locations = pagy(@locations, items: 50)
    end
  end
end
