###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module UserPermissionReport::WarehouseReports
  class UsersController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    before_action :set_group_associations

    # This controller only serves the detail modal for the report index, so authorize
    # against that report. The concern's default derives the url from this controller's
    # own :index action, which doesn't exist here.
    def related_report
      GrdaWarehouse::WarehouseReports::ReportDefinition.
        where(url: 'user_permission_report/warehouse_reports/reports')
    end

    def show
      @modal_size = :xl
      @user = User.includes(:roles, access_groups: @group_associations.keys).find(params[:id])
    end

    def set_group_associations
      @group_associations = User.group_associations
    end
  end
end
