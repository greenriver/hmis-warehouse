###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin::Roles
  class UsersController < ApplicationController
    include ActionView::Helpers::TextHelper
    before_action :require_can_edit_roles!
    before_action :set_role

    def create
      # add to the role any users passed through
      user_ids = clean_params[:user_ids].select(&:present?).map(&:to_i)
      @role.add(User.where(id: user_ids))
      flash[:notice] = "#{pluralize(user_ids.count, 'user')} added"
      redirect_to edit_admin_role_path(@role)
    end

    def destroy
      user = User.find(params[:id].to_i)
      @role.remove(user)
      flash[:notice] = "#{user.name} removed from #{@role.name}"
      redirect_to edit_admin_role_path(@role)
    end

    private def set_role
      @role = role_scope.find(params[:role_id].to_i)
    end

    private def role_scope
      Role.editable
    end

    private def clean_params
      params.require(:user_members).
        permit(user_ids: [])
    end
  end
end
