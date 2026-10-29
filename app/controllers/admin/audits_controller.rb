###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  class AuditsController < ::ApplicationController
    before_action :require_can_audit_users!

    def show
      @user = User.find params[:user_id]
      @activity_log = ActivityLog.where(user_id: @user.id).order(created_at: :desc)
      @pagy, @activity_log = pagy(@activity_log, items: 50)
      current_user.policy_context.preload_client_restrictions(@activity_log.map(&:client_id_from_path))
    end

    private

    helper_method def activity_title(activity)
      activity.display_title(name_redacted: current_user.policy_context.client_restricted?(activity.client_id_from_path))
    end
  end
end
