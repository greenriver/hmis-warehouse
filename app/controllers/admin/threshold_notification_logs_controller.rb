###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  class ThresholdNotificationLogsController < ApplicationControllerV2
    authorize_with { current_user.can_audit_users? }
    before_action :load_user

    def index
      @logs = GrdaWarehouse::Monitoring::ThresholdNotificationLog.for_user(@user.id).recent_first
    end

    def show
      @log = GrdaWarehouse::Monitoring::ThresholdNotificationLog.for_user(@user.id).find(params[:id])
      @message = Message.find_by(id: @log.message_id) if @log.message_id.present?
    end

    private

    def load_user
      @user = User.find(params[:user_id])
    end
  end
end
