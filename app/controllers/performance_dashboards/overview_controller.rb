###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module PerformanceDashboards
  class OverviewController < BaseController
    before_action :set_filter
    before_action :set_key, only: [:details]

    def index
      @report = PerformanceDashboards::Overview.new(@filter)
      if @report.include_comparison?
        @comparison = @report
      else
        @comparison = PerformanceDashboards::Overview.new(@comparison_filter)
      end
    end

    def details
    end

    private def set_key
      @key = PerformanceDashboards::Overview.detail_method(params.dig(:options, :key))
    end
  end
end
