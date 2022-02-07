###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reports::SystemPerformance::Fy2015
  class Base < Report
    def self.report_name
      'HUD System Performance Reports - FY 2015'
    end

    def report_group_name
      'System Performance Measures'
    end

    def download_type
      :csv
    end
  end
end
