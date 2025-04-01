###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module UserPermissionReport::WarehouseReports
  class ReportsController < ApplicationController
    include WarehouseReportAuthorization
    before_action :set_group_associations

    def index
      @users = User.
        order(:last_name, :first_name).
        includes(:roles, access_groups: @group_associations.keys)

      respond_to do |format|
        format.html do
          @users = @users.text_search(params[:q]) if params[:q].present?
          @pagy, @users = pagy(@users)
        end
        format.xlsx do
          @hmis_data = report_class.new(current_user).hmis_data

          date = Date.current.strftime('%Y-%m-%d')
          filename = "user-permissions-#{date}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    private def report_class
      ::UserPermissionReport::Report
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
