###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module PerformanceDashboards
  class OverviewController < BaseController
    before_action :set_filter
    before_action :set_report
    before_action :set_key, only: [:details]

    def index
      if @report.include_comparison?
        @comparison = PerformanceDashboards::Overview.new(@comparison_filter)
      else
        @comparison = @report
      end
    end

    def details
      @options = option_params[:options]
      @breakdown = params.dig(:options, :breakdown)
    end

    private def option_params
      params.permit(
        options: [
          :key,
          :age,
          :gender,
          :household_type,
          :veteran,
          :race,
          :ethnicity,
          :breakdown,
        ],
      )
    end

    private def set_report
      @report = PerformanceDashboards::Overview.new(@filter)
    end

    private def set_key
      @key = PerformanceDashboards::Overview.detail_method(params.dig(:options, :key))
    end
  end
end
