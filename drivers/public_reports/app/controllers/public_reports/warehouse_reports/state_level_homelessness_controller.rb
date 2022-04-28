###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PublicReports::WarehouseReports
  class StateLevelHomelessnessController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    include PublicReports::WarehouseReports::PublicReportsControllerConcern

    def pit
      render(layout: 'raw_public_report')
    end

    def summary
      render(layout: 'raw_public_report')
    end

    def entering_exiting
      render(layout: 'raw_public_report')
    end

    def map
      render(layout: 'raw_public_report')
    end

    def who
      render(layout: 'raw_public_report')
    end

    def race
      render(layout: 'raw_public_report')
    end

    def raw
      render(layout: 'raw_public_report')
    end

    private def path_to_report_index
      public_reports_warehouse_reports_state_level_homelessness_index_path
    end

    private def path_to_report(report = nil)
      report ||= @report
      public_reports_warehouse_reports_state_level_homelessness_path(report)
    end

    private def path_to_edit(report)
      edit_public_reports_warehouse_reports_state_level_homelessness_path(report)
    end

    private def report_source
      PublicReports::StateLevelHomelessness
    end

    private def flash_interpolation_options
      { resource_name: report_source.new.instance_title }
    end

    private def default_filter_options
      if last_report.present?
        last_report.filter_object.for_params
      else
        {
          filters: {
            start: 3.years.ago.beginning_of_year.to_date,
            end: 1.years.ago.end_of_year.to_date,
            project_type_numbers: [1, 2, 8, 4],
          },
        }
      end
    end
  end
end
