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
    @section = 'overall' if @section.blank? && params.require(:partial) == 'overall'

    raise 'Rollup not in allowlist' unless @section.present?

    @section = section_subpath + @section
    render partial: @section, layout: false if request.xhr?
  end

  def set_filter
    @filter = filter_class.new(user_id: current_user.id)
    @filter.set_from_params(filter_params[:filters]) if filter_params[:filters].present?

    @comparison_filter = @filter.deep_dup
    return if @filter.comparison_pattern == :no_comparison_period

    @comparison_filter.start = comparison_start
    @comparison_filter.end = comparison_end
  end

  private def show_client_details?
    @show_client_details ||= current_user.can_view_clients?
  end
  helper_method :show_client_details?

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

  def comparison_start
    comparison_dates(@filter.comparison_pattern).first
  end

  def comparison_end
    comparison_dates(@filter.comparison_pattern).last
  end

  def filter_params
    filtered = params.permit(
      filters: [
        :start,
        :end,
        :comparison_pattern,
        :household_type,
        :hoh_only,
        :sub_population,
        coc_codes: [],
        project_types: [],
        project_type_codes: [],
        veteran_statuses: [],
        age_ranges: [],
        genders: [],
        races: [],
        ethnicities: [],
        data_source_ids: [],
        organization_ids: [],
        project_ids: [],
        funder_ids: [],
      ],
    )
    # project_type_codes exists as both a single and multi, ensure it's always
    # an array

    filtered[:filters][:project_type_codes] = Array.wrap(params[:filters][:project_type_codes])
    filtered
  end
  helper_method :filter_params

  private def comparison_dates(pattern)
    case pattern
    when :prior_period
      prior_end = @filter[:start] - 1.days
      period_length = (@filter[:end] - @filter[:start]).to_i
      prior_start = prior_end - period_length.to_i.days
      [prior_start, prior_end]
    when :prior_year
      prior_end = @filter[:end] - 1.years
      prior_start = @filter[:start] - 1.years
      [prior_start, prior_end]
    else
      [@filter[:start], @filter[:end]]
    end
  end
end
