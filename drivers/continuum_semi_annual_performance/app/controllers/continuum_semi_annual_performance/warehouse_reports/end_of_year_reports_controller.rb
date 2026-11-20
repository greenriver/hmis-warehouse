###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ContinuumSemiAnnualPerformance::WarehouseReports
  class EndOfYearReportsController < ReportsController
    private def report_class
      ContinuumSemiAnnualPerformance::EndOfYearReport
    end
  end
end
