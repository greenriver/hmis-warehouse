###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module PerformanceDashboards
  class OverviewController < BaseController
    before_action :set_filter

    def index
      @report = PerformanceDashboards::Overview.new(
        start_date: @start_date,
        end_date: @end_date,
        coc_codes: @coc_codes,
        household_type: @household_type,
        hoh_only: @hoh_only,
        age_ranges: @age_ranges,
        genders: @genders,
        races: @races,
        ethnicities: @ethnicities,
        veteran_statuses: @veteran_statuses,
        project_types: @project_types,
      )
      if @comparison_pattern == :no_comparison_period
        @comparison = @report
      else
        @comparison = PerformanceDashboards::Overview.new(
          start_date: comparison_start,
          end_date: comparison_end,
          coc_codes: @coc_codes,
          household_type: @household_type,
          hoh_only: @hoh_only,
          age_ranges: @age_ranges,
          genders: @genders,
          races: @races,
          ethnicities: @ethnicities,
          veteran_statuses: @veteran_statuses,
          project_types: @project_types,
        )
      end
    end
  end
end
