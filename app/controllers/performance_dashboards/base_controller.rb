###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class PerformanceDashboards::BaseController < ApplicationController
  def set_filter
    @end_date = params.dig(:filters, :end_date)&.to_date || Date.current
    @start_date = params.dig(:filters, :start_date)&.to_date || @end_date - 1.year
    ensure_dates_work

    @comparison_pattern = comparison_pattern
    @coc_codes = params.dig(:filters, :coc_codes)&.select { |code| PerformanceDashboards::Overview.coc_codes.include?(code) } || []
    @household_type = params.dig(:filters, :household_type)&.to_sym
    @hoh_only = params.dig(:filters, :hoh_only) == '1'
    @project_type_codes = params.dig(:filters, :project_types)&.reject { |type| type.blank? } || GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING.keys
    @project_types = @project_type_codes.map { |type| GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING[type.to_sym] }.flatten if @project_type_codes.present?
    @veteran_statuses = params.dig(:filters, :veteran_statuses)&.reject { |status| status.blank? }&.map { |status| status.to_i } || []
    @age_ranges = params.dig(:filters, :age_ranges)&.reject { |range| range.blank? }&.map { |range| range.to_sym } || []
    @genders = params.dig(:filters, :genders)&.reject { |gender| gender.blank? }&.map { |gender| gender.to_i } || []
    races = params.dig(:filters, :races)&.select { |race| HUD.races.keys.include?(race) } || []
    @races = races.map { |race| [race, 1] }.to_h
    @ethnicities = params.dig(:filters, :ethnicities)&.reject { |ethnicity| ethnicity.blank? }&.map { |ethnicity| ethnicity.to_i } || []
  end

  private def ensure_dates_work
    return if @end_date > @start_date

    new_start = @end_date
    @end_date = @start_date
    @start_date = new_start
  end

  private def comparison_pattern
    pattern = params.dig(:filters, :comparison_pattern)
    return pattern&.to_sym if PerformanceDashboards::Overview.valid_comparison_pattern?(pattern)

    PerformanceDashboards::Overview.comparison_patterns.values.first
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
      period_length = (@end_date - @start_date).to_i
      prior_start = prior_end - period_length.to_i.days
      [prior_start, prior_end]
    when :prior_year
      prior_end = @end_date - 1.years
      prior_start = @start_date - 1.years
      [prior_start, prior_end]
    else
      [@start_date, @end_date]
    end
  end
end
