###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
