###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ReportResultsSummaries::DataQuality
  class Base < ReportResultsSummary
    def report_download_format
      :csv
    end
  end
end
