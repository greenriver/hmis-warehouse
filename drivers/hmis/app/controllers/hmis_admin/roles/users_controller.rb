###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisAdmin
  class Roles::UsersController < ApplicationController
    include ActionView::Helpers::TextHelper
    include EnforceHmisEnabled

    before_action :require_hmis_admin_access!
    before_action :set_role

    def create
      # add to the role any users passed through
      user_ids = clean_params[:user_ids].select(&:present?).map(&:to_i)
      @role.add(Hmis::User.where(id: user_ids))
      flash[:notice] = "#{pluralize(user_ids.count, 'user')} added"
      redirect_to edit_hmis_admin_role_path(@role)
    end

    def destroy
      user = Hmis::User.find(params[:id].to_i)
      @role.remove(user)
      flash[:notice] = "#{user.name} removed from #{@role.name}"
      redirect_to edit_hmis_admin_role_path(@role)
    end

    private def set_role
      @role = role_scope.find(params[:role_id].to_i)
    end

    private def role_scope
      Hmis::Role
    end

    private def clean_params
      params.require(:user_members).
        permit(user_ids: [])
    end
  end
end
