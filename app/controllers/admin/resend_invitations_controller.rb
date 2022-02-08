###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class ResendInvitationsController < ::ApplicationController
    before_action :require_can_edit_users!

    def create
      @user = User.find params[:user_id]
      @user.deliver_invitation
      flash[:notice] = "Account activation instructions resent to #{@user.email}"
      redirect_to admin_users_path
    end
  end
end
