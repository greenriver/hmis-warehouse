###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ReportResultsSummaries::Ahar
  class Fy2017 < Base
    def report_start
      '2016-10-01'
    end
    def report_end
      '2017-09-30'
    end
  end
end
