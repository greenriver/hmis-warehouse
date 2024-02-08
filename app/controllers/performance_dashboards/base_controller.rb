###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
    @show_client_details ||= current_user.can_access_some_version_of_clients?
  end
  helper_method :show_client_details?

  def breakdown
    # This is needed when generating the PDF
    if @report.blank?
      set_filter
      set_report
    end
    @breakdown ||= params[:breakdown]&.to_sym || @report.available_breakdowns.keys.first
  end
  helper_method :breakdown

  def filter_params
    filtered = params.permit(filters: @filter.known_params)
    # project_type_codes exists as both a single and multi, ensure it's always
    # an array
    if params.dig(:filters, :project_type_codes).is_a?(String)
      filtered[:filters][:project_type_codes] = Array.wrap(params[:filters][:project_type_codes])
    elsif params.dig(:filters, :project_type_codes)&.reject(&:blank?).blank? && params[:filters]&.key?(:project_type_codes)
      # Enforce that we always have _some_ project types
      filtered[:filters][:project_type_codes] = @filter.default_project_type_codes
    end
    filtered
  end
  helper_method :filter_params
end
