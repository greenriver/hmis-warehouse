###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ContinuumSemiAnnualPerformance
  class MidYearReport < Report
    # The archive task selects reports by their exact STI type
    ReportArchival.register_report_type(self)

    def self.url
      'continuum_semi_annual_performance/warehouse_reports/mid_year_reports'
    end

    def self.controller_class
      ContinuumSemiAnnualPerformance::WarehouseReports::MidYearReportsController
    end

    def project_types
      [:es, :hp, :so, :rrh]
    end

    def default_project_type_codes
      project_types.map { |project_type| PERFORMANCE_KEYS.fetch(project_type) }
    end

    def row_set
      :mid_year
    end

    def title
      'CoC Mid-Year Performance Report'
    end

    def description
      'Summary of APR and CE APR performance by project type as defined for mid-year reporting.'
    end
  end
end
