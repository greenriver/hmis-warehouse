###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ReportResultsSummaries::DataQuality
  class Fy2016 < Base
    def report_start
      '2015-10-01'
    end
    def report_end
      '2016-09-30'
    end
  end
end
