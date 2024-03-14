###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisAdmin::UserGroupsController < ApplicationController
  include EnforceHmisEnabled

  before_action :require_hmis_admin_access!
  before_action :set_user_group, only: [:edit, :update, :destroy]

  def index
    @user_groups = user_group_scope.order(:name)
    @user_groups = @user_groups.text_search(params[:q]) if params[:q].present?
    @pagy, @user_groups = pagy(@user_groups)
  end

  def new
    @user_group = user_group_scope.new
  end

  def create
    @user_group = user_group_scope.new
    @user_group.update(user_group_params)

    respond_with(@user_group, location: hmis_admin_user_groups_path)
  end

  def edit
  end

  def update
    @user_group.update(user_group_params)
    # add any users passed through to the Access Control List
    # user_ids = user_params[:user_ids].select(&:present?).map(&:to_i)
    # users = Hmis::User.where(id: user_ids)
    # @user_group.add(users) if users.any?

    redirect_to({ action: :index }, notice: "User Group #{@user_group.name} updated.")
  end

  def destroy
    @user_group.destroy
    redirect_to({ action: :index }, notice: "User Group #{@user_group.name} removed.")
  end

  private def user_group_scope
    Hmis::UserGroup
  end

  private def user_group_params
    params.require(:user_group).permit(
      :name,
    )
  end

  private def user_params
    params.require(:user_group).permit(
      :name,
    )
  end

  private def set_user_group
    @user_group = user_group_scope.find(params[:id].to_i)
  end
end
