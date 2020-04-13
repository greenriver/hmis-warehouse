###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class PerformanceDashboards::BaseController < ApplicationController
  include WarehouseReportAuthorization
  include PjaxModalController

  def set_filter
    @filter = OpenStruct.new
    @filter.end_date = params.dig(:filters, :end_date)&.to_date || defaults.end_date
    @filter.start_date = params.dig(:filters, :start_date)&.to_date || defaults.start_date
    ensure_dates_work

    @filter.comparison_pattern = comparison_pattern
    @filter.coc_codes = params.dig(:filters, :coc_codes)&.select { |code| PerformanceDashboards::Overview.coc_codes.include?(code) } || defaults.coc_codes
    @filter.household_type = params.dig(:filters, :household_type)&.to_sym || defaults.household_type
    @filter.hoh_only = params.dig(:filters, :hoh_only) == '1' || defaults.hoh_only
    @filter.project_type_codes = params.dig(:filters, :project_types)&.reject { |type| type.blank? } || defaults.project_type_codes
    @filter.project_types = @filter.project_type_codes.map { |type| GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING[type.to_sym] }.flatten if @filter.project_type_codes.present?
    @filter.veteran_statuses = params.dig(:filters, :veteran_statuses)&.reject { |status| status.blank? }&.map { |status| status.to_i } || defaults.veteran_statuses
    @filter.age_ranges = params.dig(:filters, :age_ranges)&.reject { |range| range.blank? }&.map { |range| range.to_sym } || defaults.age_ranges
    @filter.genders = params.dig(:filters, :genders)&.reject { |gender| gender.blank? }&.map { |gender| gender.to_i } || defaults.genders
    @filter.sub_population = params.dig(:filters, :sub_population)&.to_sym || defaults.sub_population
    races = params.dig(:filters, :races)&.select { |race| HUD.races.keys.include?(race) } || defaults.races
    @filter.races = races.map { |race| [race, 1] }.to_h
    @filter.ethnicities = params.dig(:filters, :ethnicities)&.reject { |ethnicity| ethnicity.blank? }&.map { |ethnicity| ethnicity.to_i } || defaults.ethnicities

    @comparison_filter = @filter.deep_dup
    return if @filter.comparison_pattern == :no_comparison_period

    @comparison_filter.start_date = comparison_start
    @comparison_filter.end_date = comparison_end
  end

  private def show_client_details?
    @show_client_details ||= current_user.can_view_clients?
  end
  helper_method :show_client_details?

  def defaults
    OpenStruct.new(
      end_date: Date.current,
      start_date: Date.current - 1.year,
      comparison_pattern: PerformanceDashboards::Overview.comparison_patterns.values.first,
      coc_codes: [],
      household_type: nil,
      hoh_only: nil,
      project_type_codes: GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING.keys,
      veteran_statuses: [],
      age_ranges: [],
      sub_population: :all_clients,
      genders: [],
      races: [],
      ethnicities: [],
    )
  end
  helper_method :defaults

  def filter_open
    return 'yes' unless params[:filters].present?

    'no'
  end
  helper_method :filter_open

  def breakdown
    @breakdown ||= params[:breakdown]&.to_sym || :age
  end
  helper_method :breakdown

  private def available_breakdowns
    {
      age: 'By Age',
      gender: 'By Gender',
      household: 'By Household Type',
      veteran: 'By Veteran Status',
      race: 'By Race',
      ethnicity: 'By Ethnicity',
    }
  end

  private def ensure_dates_work
    @filter[:end_date] = @filter[:start_date] + 1.years if @filter[:end_date] - @filter[:start_date] > 365
    return if @filter[:end_date] > @filter[:start_date]

    new_start = @filter[:end_date]
    @filter[:end_date] = @filter[:start_date]
    @filter[:start_date] = new_start
    @filter[:end_date] = @filter[:start_date] + 1.years if @filter[:end_date] - @filter[:start_date] > 365
  end

  private def comparison_pattern
    pattern = params.dig(:filters, :comparison_pattern)
    return pattern&.to_sym if PerformanceDashboards::Overview.valid_comparison_pattern?(pattern)

    defaults[:comparison_pattern]
  end

  def comparison_start
    comparison_dates(@filter[:comparison_pattern]).first
  end

  def comparison_end
    comparison_dates(@filter[:comparison_pattern]).last
  end

  def filter_params
    params.permit(
      filters: [
        :end_date,
        :start_date,
        :household_type,
        :hoh_only,
        coc_codes: [],
        project_types: [],
        veteran_statuses: [],
        age_ranges: [],
        genders: [],
        races: [],
        ethnicities: [],
      ],
    )
  end
  helper_method :filter_params

  private def comparison_dates(pattern)
    case pattern
    when :prior_period
      prior_end = @filter[:start_date] - 1.days
      period_length = (@filter[:end_date] - @filter[:start_date]).to_i
      prior_start = prior_end - period_length.to_i.days
      [prior_start, prior_end]
    when :prior_year
      prior_end = @filter[:end_date] - 1.years
      prior_start = @filter[:start_date] - 1.years
      [prior_start, prior_end]
    else
      [@filter[:start_date], @filter[:end_date]]
    end
  end
end
