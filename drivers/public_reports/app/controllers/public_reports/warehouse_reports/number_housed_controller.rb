###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PublicReports::WarehouseReports
  class NumberHousedController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    include PublicReports::WarehouseReports::PublicReportsControllerConcern

    private def path_to_report_index
      public_reports_warehouse_reports_number_housed_index_path
    end

    private def path_to_report(report = nil)
      report ||= @report
      public_reports_warehouse_reports_number_housed_path(report)
    end

    private def path_to_edit(report)
      edit_public_reports_warehouse_reports_number_housed_path(report)
    end

    private def report_source
      PublicReports::NumberHoused
    end

    private def flash_interpolation_options
      { resource_name: 'Number Housed Report' }
    end

    private def default_filter_options
      {
        filters: {
          start: 1.years.ago.beginning_of_year.to_date,
          end: 1.years.ago.end_of_year.to_date,
        },
      }
    end
  end
end
