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
    @comparison_filter = @filter.to_comparison
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

    filtered[:filters][:project_type_codes] = Array.wrap(params[:filters][:project_type_codes]) if params.dig(:filters, :project_type_codes).is_a?(String)
    filtered
  end
  helper_method :filter_params

  def filter_item_selection_summary(value)
    render_to_string partial: "/performance_dashboards/filter_controls/helpers/items_selection_summary", locals: {value: value}
  end
  helper_method :filter_item_selection_summary

end
