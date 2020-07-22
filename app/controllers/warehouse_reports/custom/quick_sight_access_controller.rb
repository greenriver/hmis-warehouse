###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Custom
  class QuickSightAccessController < ApplicationController
    include WarehouseReportAuthorization

    def index
    end

    def create
    end

    def flash_interpolation_options
      { resource_name: 'QuickSight Access' }
    end
  end
end
