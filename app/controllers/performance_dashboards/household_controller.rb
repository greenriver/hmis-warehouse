###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboards
  class HouseholdController < OverviewController
    before_action :set_filter
    before_action :set_report
    before_action :set_key, only: [:details]

    def index
    end

    def filters
      @sections = @filter.control_sections
      chosen = params[:filter_section_id]
      if chosen
        @chosen_section = @sections.detect do |section|
          section.id == chosen
        end
      end
      @modal_size = :xl if @chosen_section.nil?
    end

    private def section_subpath
      'performance_dashboards/household/'
    end
    helper_method :section_subpath

    private def option_params
      params.permit(
        filters: [
          :key,
          :sub_key,
          :household,
          :sub_population,
          :project_type,
          :coc,
          :breakdown,
        ],
      )
    end

    private def set_report
      @report_variant = 'sparse'
      @report = PerformanceDashboards::Household.new(@filter)
      if @report.include_comparison?
        @comparison = PerformanceDashboards::Household.new(@comparison_filter)
      else
        @comparison = @report
      end
    end

    private def set_key
      @key = PerformanceDashboards::Household.detail_method(params.dig(:filters, :key))
    end

    private def performance_type
      'Household'
    end
    helper_method :performance_type
  end
end
