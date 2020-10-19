###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class PerformanceDashboards::BaseController < ApplicationController
  include WarehouseReportAuthorization
  include AjaxModalRails::Controller
  include BaseFilters

  def section
    @section = @report.class.available_chart_types.detect do |m|
      m == params.require(:partial).underscore
    end
    @section = 'overall' if @section.blank? && params.require(:partial) == 'overall'

    raise 'Rollup not in allowlist' unless @section.present?

    @section = @report.section_subpath + @section
    render partial: @section, layout: false if request.xhr?
  end

  private def show_client_details?
    @show_client_details ||= current_user.can_view_clients?
  end
  helper_method :show_client_details?

  def breakdown
    @breakdown ||= params[:breakdown]&.to_sym || @report.available_breakdowns.keys.first
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
        project_group_ids: [],
        prior_living_situation_ids: [],
        destination_ids: [],
      ],
    )
    # project_type_codes exists as both a single and multi, ensure it's always
    # an array

    filtered[:filters][:project_type_codes] = Array.wrap(params[:filters][:project_type_codes]) if params.dig(:filters, :project_type_codes).is_a?(String)
    filtered
  end
  helper_method :filter_params
end
