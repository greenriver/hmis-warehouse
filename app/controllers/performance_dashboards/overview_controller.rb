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

    def comparison_start
      comparison_dates(@comparison_pattern).first
    end

    def comparison_end
      comparison_dates(@comparison_pattern).last
    end

    private def comparison_dates(pattern)
      case pattern
      when :prior_period
        prior_end = @start_date - 1.days
      when :prior_year
        prior_end = @end_date - 1.years
      end

      prior_start = prior_end - (@end_date - @start_date).to_i.days
      [prior_start, prior_end]
    end
  end
end
