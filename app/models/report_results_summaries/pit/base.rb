###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ReportResultsSummaries::Pit
  class Base < ReportResultsSummary
    def report_download_format
      nil
    end
  end
end
