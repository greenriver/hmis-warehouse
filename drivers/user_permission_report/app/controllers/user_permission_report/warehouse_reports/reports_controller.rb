###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
module UserPermissionReport::WarehouseReports
  class ReportsController < ApplicationController
    before_action :set_group_associations

    def index
      @users = User.active.
        order(:last_name, :first_name).
        includes(:roles, access_groups: @group_associations.keys)
      respond_to do |format|
        format.html do
          @users = @users.text_search(params[:q]) if params[:q].present?
          @users = @users.page(params[:page]).per(25)
        end
        format.xlsx do
          date = Date.current.strftime('%Y-%m-%d')
          filename = "user-permissions-#{date}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    private def set_group_associations
      @group_associations = User.group_associations
    end

    def associated_items(user, meth)
      return nil unless @group_associations.keys.include? meth

      items = user.access_groups.map { |g| g.public_send(meth) }.flatten.uniq
      {
        count: items.count,
        names: items.map(&:name),
        total: @group_associations[meth].count,
      }
    end
    helper_method :associated_items
  end
end
