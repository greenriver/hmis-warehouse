###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin::Groups
  class UsersController < ApplicationController
    include ActionView::Helpers::TextHelper
    before_action :require_can_edit_access_groups!
    before_action :set_group

    def create
      # add to the access group any users passed through
      user_ids = clean_params[:user_ids].select(&:present?).map(&:to_i)
      @group.add(User.where(id: user_ids))
      flash[:notice] = "#{pluralize(user_ids.count, 'user')} added"
      redirect_to edit_admin_group_path(@group)
    end

    def destroy
      user = User.find(params[:id].to_i)
      @group.remove(user)
      flash[:notice] = "#{user.name} removed from #{@group.name}"
      redirect_to edit_admin_group_path(@group)
    end

    private def set_group
      @group = access_group_scope.find(params[:group_id].to_i)
    end

    private def access_group_scope
      AccessGroup.general
    end

    private def clean_params
      params.require(:user_members).
        permit(user_ids: [])
    end
  end
end
