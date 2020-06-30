###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboards
  class ProjectTypeController < BaseController
    before_action :set_filter
    before_action :set_report
    before_action :set_key, only: [:details]

    def index
    end

    private def section_subpath
      'performance_dashboards/project_type/'
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
          :living_situation,
          :destination,
          :length_of_time,
          :returns,
          :breakdown,
        ],
      )
    end

    # def filter_params
    #   params.permit(
    #     filters: [
    #       :end_date,
    #       :start_date,
    #       :household_type,
    #       :hoh_only,
    #       :sub_population,
    #       :project_types,
    #       coc_codes: [],
    #       veteran_statuses: [],
    #       age_ranges: [],
    #       genders: [],
    #       races: [],
    #       ethnicities: [],
    #     ],
    #   )
    # end
    # helper_method :filter_params

    private def default_project_types
      [:es]
    end

    private def multiple_project_types?
      false
    end
    helper_method :multiple_project_types?

    private def set_report
      @report = PerformanceDashboards::ProjectType.new(@filter)
      if @report.include_comparison?
        @comparison = PerformanceDashboards::ProjectType.new(@comparison_filter)
      else
        @comparison = @report
      end
    end

    private def set_key
      @key = PerformanceDashboards::ProjectType.detail_method(params.dig(:options, :key))
    end
  end
end
