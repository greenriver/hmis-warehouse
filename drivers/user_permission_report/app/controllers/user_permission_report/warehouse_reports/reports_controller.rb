###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module UserPermissionReport::WarehouseReports
  class ReportsController < ApplicationController

    before_action :set_group_associations

    def index
      if params[:q].present?
        @users = User.active.
          text_search(params[:q]).
          order(:last_name, :first_name).
          includes(:roles, access_groups: @group_associations).
          page(params[:page]).per(25)
      else
        @users = User.active.order(:last_name, :first_name).includes(:roles, access_groups: @group_associations).page(params[:page]).per(25)
      end
    end

    private def set_group_associations
      @group_associations = [
        :data_sources,
        :organizations,
        :projects,
        :reports,
        :cohorts,
        :project_groups,
      ]
    end

    def associated_items(user, meth)
      unless @group_associations.include? meth
        return nil
      end
      user.access_groups.map{|g| g.public_send(meth)}.flatten.map(&:name)
    end
    helper_method :associated_items
  end
end
