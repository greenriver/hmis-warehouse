###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ContinuumSemiAnnualPerformance
  class EndOfYearReport < Report
    # The archive task selects reports by their exact STI type
    ReportArchival.register_report_type(self)

    def self.url
      'continuum_semi_annual_performance/warehouse_reports/end_of_year_reports'
    end

    def self.controller_class
      ContinuumSemiAnnualPerformance::WarehouseReports::EndOfYearReportsController
    end

    def project_types
      [:es, :hp, :so, :rrh, :ce_tab]
    end

    def row_set
      :end_of_year
    end

    def title
      'CoC End of Year Performance Report'
    end

    def description
      'Summary of APR and CE APR performance by project type as defined for end of year reporting.'
    end
  end
end
