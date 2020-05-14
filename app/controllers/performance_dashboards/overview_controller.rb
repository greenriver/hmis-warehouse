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
    end

    def details
      @options = option_params[:options]
      @breakdown = params.dig(:options, :breakdown)
      @sub_key = params.dig(:options, :sub_key)
      if params.dig(:options, :report) == 'comparison'
        @detail = @comparison
      else
        @detail = @report
      end
    end

    private def option_params
      params.permit(
        options: [
          :key,
          :sub_key,
          :age,
          :gender,
          :household,
          :veteran,
          :sub_population,
          :race,
          :ethnicity,
          :breakdown,
        ],
      )
    end

    private def multiple_project_types?
      true
    end
    helper_method :multiple_project_types?

    private def default_project_types
      GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING.keys
    end

    private def set_report
      @report = PerformanceDashboards::Overview.new(@filter)
      if @report.include_comparison?
        @comparison = PerformanceDashboards::Overview.new(@comparison_filter)
      else
        @comparison = @report
      end
    end

    private def set_key
      @key = PerformanceDashboards::Overview.detail_method(params.dig(:options, :key))
    end
  end
end
