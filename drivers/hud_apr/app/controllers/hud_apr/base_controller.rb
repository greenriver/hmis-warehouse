###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr
  class BaseController < ::HudReports::BaseController
    before_action :filter

    def available_report_versions
      {
        'FY 2020' => :fy2020,
        'FY 2021' => :fy2021,
      }.freeze
    end
    helper_method :available_report_versions

    def default_report_version
      :fy2020
    end

    private def filter_class
      ::Filters::HudFilterBase
    end
  end
end
