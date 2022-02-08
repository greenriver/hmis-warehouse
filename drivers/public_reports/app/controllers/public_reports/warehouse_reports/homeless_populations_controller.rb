###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PublicReports::WarehouseReports
  class HomelessPopulationsController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    include PublicReports::WarehouseReports::PublicReportsControllerConcern

    def overall
      render(layout: 'raw_public_report')
    end

    def housed
      render(layout: 'raw_public_report')
    end

    def individuals
      render(layout: 'raw_public_report')
    end

    def adults_with_children
      render(layout: 'raw_public_report')
    end

    def veterans
      render(layout: 'raw_public_report')
    end

    private def path_to_report_index
      public_reports_warehouse_reports_homeless_populations_path
    end

    private def path_to_report(report = nil)
      report ||= @report
      public_reports_warehouse_reports_homeless_population_path(report)
    end

    private def path_to_edit(report)
      edit_public_reports_warehouse_reports_homeless_population_path(report)
    end

    private def report_source
      PublicReports::HomelessPopulation
    end

    private def flash_interpolation_options
      { resource_name: 'Homeless Population Report' }
    end

    private def default_filter_options
      {
        filters: {
          start: 1.years.ago.beginning_of_year.to_date,
          end: 1.years.ago.end_of_year.to_date,
          project_type_numbers: [1, 2, 3, 4, 8, 9, 10, 13],
        },
      }
    end
  end
end
