###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class UserGroupsController < ApplicationController
    before_action :require_can_edit_users!
    before_action :set_group, only: [:edit, :update, :destroy]

    def index
      @groups = user_group_scope.order(:name)
      @pagy, @groups = pagy(@groups)
    end

    def new
      @group = user_group_scope.new
    end

    def create
      @group = user_group_scope.new
      @group.update(group_params)
      @group.save
      respond_with(@group, location: edit_admin_user_group_path(@group))
    end

    def edit
    end

    def update
      @group.update(group_params)
      @group.save
      respond_with(@group, location: edit_admin_user_group_path(@group))
    end

    def destroy
      @group.destroy
      respond_with(@group, location: admin_user_groups_path)
    end

    private def user_group_scope
      UserGroup.not_system
    end

    private def group_params
      params.require(:user_group).permit(
        :name,
        user_ids: [],
      )
    end

    private def set_group
      @group = UserGroup.find(params[:id].to_i)
    end
  end
end
