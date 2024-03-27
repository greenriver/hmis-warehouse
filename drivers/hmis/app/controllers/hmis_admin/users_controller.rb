###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisAdmin::UsersController < ApplicationController
  include EnforceHmisEnabled

  before_action :require_hmis_admin_access!
  before_action :set_user, only: [:edit, :update]

  def index
    @users = user_scope.order(last_name: :asc, first_name: :asc)
    @users = @users.text_search(params[:q]) if params[:q].present?
  end

  def edit
  end

  def update
    @user.update(user_params)
    copy_user_groups
    respond_with(@user, location: edit_hmis_admin_user_path(@user))
  end

  private def set_user
    @user = user_scope.find(params[:id].to_i)
  end

  private def user_scope
    Hmis::User.active.not_system
  end

  private def copy_user_groups
    return unless @user
    return unless user_params[:copy_form_id].present?

    source_user = Hmis::User.active.find(user_params[:copy_form_id].to_i)
    return unless source_user

    source_user.user_groups.each do |group|
      group.add(@user)
    end
  end

  private def user_params
    params.require(:user).
      permit(
        :copy_form_id,
        user_group_ids: [],
      )
  end

  def flash_interpolation_options
    { resource_name: 'User' }
  end
end
