###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module UserPermissionReport::WarehouseReports
  class UsersController < ApplicationController
    include AjaxModalRails::Controller
    before_action :set_group_associations

    def show
      @modal_size = :xl
      @user = User.includes(:roles, access_groups: @group_associations.keys).find(params[:id])
    end

    def set_group_associations
      @group_associations = User.group_associations
    end
  end
end
