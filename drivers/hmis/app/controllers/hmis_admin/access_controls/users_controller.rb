###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisAdmin::AccessControls
  class UsersController < ApplicationController
    include ActionView::Helpers::TextHelper
    before_action :require_can_edit_access_groups!
    before_action :set_access_control_list

    def create
      # add any users passed through to the Access Control List
      user_ids = clean_params[:user_ids].select(&:present?).map(&:to_i)
      users = Hmis::User.where(id: user_ids)
      return unless users.any?

      @acl.add(users)
      flash[:notice] = "#{pluralize(users.count, 'user')} added"
      redirect_to edit_hmis_admin_access_control_path(@acl)
    end

    def destroy
      users = Hmis::User.where(id: params[:id].to_i)
      return unless users.any?

      @acl.remove(users)
      flash[:notice] = "#{users.first.name} removed"
      redirect_to edit_hmis_admin_access_control_path(@acl)
    end

    private def set_access_control_list
      @acl = Hmis::AccessControl.find(params[:access_control_id].to_i)
    end

    private def clean_params
      params.require(:user_members).
        permit(user_ids: [])
    end
  end
end
