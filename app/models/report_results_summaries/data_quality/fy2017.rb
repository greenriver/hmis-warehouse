###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ReportResultsSummaries::DataQuality
  class Fy2017 < Base
    def report_start
      '2016-10-01'
    end
    def report_end
      '2017-09-30'
    end
  end
end
