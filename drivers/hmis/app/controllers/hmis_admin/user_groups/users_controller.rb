###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisAdmin::UserGroups
  class UsersController < ApplicationController
    include ActionView::Helpers::TextHelper
    include EnforceHmisEnabled

    before_action :require_hmis_admin_access!
    before_action :set_user_group

    def create
      # add any users passed through to the Access Control List
      user_ids = clean_params[:user_ids].select(&:present?).map(&:to_i)
      users = Hmis::User.where(id: user_ids)
      return unless users.any?

      @user_group.add(users)
      flash[:notice] = "#{pluralize(users.count, 'user')} added"
      redirect_to edit_hmis_admin_user_group_path(@user_group)
    end

    def destroy
      users = Hmis::User.where(id: params[:id].to_i)
      return unless users.any?

      @user_group.remove(users)
      flash[:notice] = "#{users.first.name} removed"
      redirect_to edit_hmis_admin_user_group_path(@user_group)
    end

    private def set_user_group
      @user_group = Hmis::UserGroup.find(params[:user_group_id].to_i)
    end

    private def clean_params
      params.require(:user_members).
        permit(user_ids: [])
    end
  end
end
