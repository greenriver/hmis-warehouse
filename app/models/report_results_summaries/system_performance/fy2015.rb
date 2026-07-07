###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ReportResultsSummaries::SystemPerformance
  class Fy2015 < Base
    def report_start
      '2014-10-01'
    end
    def report_end
      '2015-09-30'
    end
  end
end
