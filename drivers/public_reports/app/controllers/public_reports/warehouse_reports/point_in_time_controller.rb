###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PublicReports::WarehouseReports
  class PointInTimeController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    include PublicReports::WarehouseReports::PublicReportsControllerConcern

    private def path_to_report_index
      public_reports_warehouse_reports_point_in_time_index_path
    end

    private def path_to_report
      public_reports_warehouse_reports_point_in_time_path(@report)
    end

    private def report_source
      PublicReports::PointInTime
    end

    private def flash_interpolation_options
      { resource_name: 'Point-in-Time Report' }
    end
  end
end
