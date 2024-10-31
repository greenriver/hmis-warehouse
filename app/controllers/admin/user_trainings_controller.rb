###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class UserTrainingsController < ApplicationController
    before_action :require_can_edit_users!
    before_action :set_user, only: [:edit, :update]

    def edit
    end

    def update
      @user.update(allowed_params)
      respond_with(@user, location: edit_admin_user_training_path)
    end

    private def set_user
      @user = User.find(params[:id].to_i)
    end

    def allowed_params
      params.require(:user).permit(
        training_courses: [],
      )
    end
  end
end
