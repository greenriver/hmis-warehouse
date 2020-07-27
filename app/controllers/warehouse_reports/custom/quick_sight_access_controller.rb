###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Custom
  class QuickSightAccessController < ApplicationController
    include WarehouseReportAuthorization

    def index
      raise 'Access denied' unless AwsQuickSight.new.available_to?(current_user)

      redirect_to AwsQuickSight.new.sign_in_url(
        user: current_user,
        return_to_url: root_url + '/warehouse_reports/custom/quick_sight_access',
      )
    end

    def create
    end

    def flash_interpolation_options
      { resource_name: 'QuickSight Access' }
    end
  end
end
