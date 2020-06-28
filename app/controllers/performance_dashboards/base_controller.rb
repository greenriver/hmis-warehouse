###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class PerformanceDashboards::BaseController < ApplicationController
  include WarehouseReportAuthorization
  include PjaxModalController

  def section
    @section = @report.class.available_chart_types.detect do |m|
      m == params.require(:partial).underscore
    end

    raise 'Rollup not in allowlist' unless @section.present?

    @section = section_subpath + @section
    render partial: @section, layout: false if request.xhr?
  end

  def set_filter
    @filter = OpenStruct.new
    @filter.user = current_user
    @filter.end_date = params.dig(:filters, :end_date)&.to_date || defaults.end_date
    @filter.start_date = params.dig(:filters, :start_date)&.to_date || defaults.start_date
    ensure_dates_work

    @filter.comparison_pattern = comparison_pattern
    @filter.coc_codes = params.dig(:filters, :coc_codes)&.select { |code| PerformanceDashboards::Overview.coc_codes.include?(code) } || defaults.coc_codes
    @filter.household_type = params.dig(:filters, :household_type)&.to_sym || defaults.household_type
    @filter.hoh_only = params.dig(:filters, :hoh_only) == '1' || defaults.hoh_only
    # NOTE: params[:filters][:project_types] will be 'es', 'th', etc.
    # the report expects @filter.project_types to be an array of integers 1, 2 etc.

    @filter.project_type_codes = Array.wrap(params.dig(:filters, :project_type_codes))&.reject { |type| type.blank? }.presence || defaults.project_type_codes
    @filter.project_types = @filter.project_type_codes.map { |type| GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING[type.to_sym] }.flatten
    @filter.data_source_ids = params.dig(:filters, :data_source_ids)&.reject(&:blank?)&.map(&:to_i) || defaults.data_source_ids
    @filter.organization_ids = params.dig(:filters, :organization_ids)&.reject(&:blank?)&.map(&:to_i) || defaults.organization_ids
    @filter.project_ids = params.dig(:filters, :project_ids)&.reject(&:blank?)&.map(&:to_i) || defaults.project_ids
    @filter.veteran_statuses = params.dig(:filters, :veteran_statuses)&.reject(&:blank?)&.map(&:to_i) || defaults.veteran_statuses
    @filter.age_ranges = params.dig(:filters, :age_ranges)&.reject(&:blank?)&.map { |range| range.to_sym } || defaults.age_ranges
    @filter.genders = params.dig(:filters, :genders)&.reject(&:blank?)&.map { |gender| gender.to_i } || defaults.genders
    @filter.sub_population = params.dig(:filters, :sub_population)&.to_sym || defaults.sub_population
    races = params.dig(:filters, :races)&.select { |race| HUD.races.keys.include?(race) } || defaults.races
    @filter.races = races.map { |race| [race, 1] }.to_h
    @filter.ethnicities = params.dig(:filters, :ethnicities)&.reject(&:blank?)&.map { |ethnicity| ethnicity.to_i } || defaults.ethnicities

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
      end_date: (Date.current - 1.year).end_of_year,
      start_date: (Date.current - 1.year).beginning_of_year,
      comparison_pattern: default_comparison_pattern,
      coc_codes: [],
      household_type: :all,
      hoh_only: nil,
      project_type_codes: default_project_types,
      veteran_statuses: [],
      age_ranges: [],
      sub_population: :all_clients,
      genders: [],
      races: [],
      ethnicities: [],
      data_source_ids: [],
      organization_ids: [],
      project_ids: [],
    )
  end
  helper_method :defaults

  def filter_open
    return 'yes' unless params[:filters].present?

    'no'
  end
  helper_method :filter_open

  def active_filter_open
    return 'yes' if params[:filters].present?

    'no'
  end
  helper_method :active_filter_open

  def breakdown
    @breakdown ||= params[:breakdown]&.to_sym || :age
  end
  helper_method :breakdown

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
        :sub_population,
        coc_codes: [],
        project_types: [],
        veteran_statuses: [],
        age_ranges: [],
        genders: [],
        races: [],
        ethnicities: [],
        data_source_ids: [],
        organization_ids: [],
        project_ids: [],
      ],
    )
  end
  helper_method :filter_params

  private def available_cocs
    GrdaWarehouse::Lookups::CocCode.as_select_options(current_user)
  end
  helper_method :available_cocs

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
