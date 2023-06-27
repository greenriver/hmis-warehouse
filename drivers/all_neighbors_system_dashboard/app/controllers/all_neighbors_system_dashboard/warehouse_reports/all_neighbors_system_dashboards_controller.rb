###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AllNeighborsSystemDashboard::WarehouseReports
  class AllNeighborsSystemDashboardsController < ApplicationController
    include WarehouseReportAuthorization
    include BaseFilters

    before_action :set_report, except: [:index, :create]

    def index
      @pagy, @reports = pagy(report_scope.ordered)
      @report = report_class.new(user_id: current_user.id)
      @filter.default_project_type_codes = @report.default_project_type_codes
      previous_report = report_scope.where(user_id: current_user.id).last
      @filter.update(previous_report.options) if previous_report

      # Make sure the form will work
      filters
    end

    def filter_params
      site_coc_codes = GrdaWarehouse::Config.get(:site_coc_codes).presence&.split(/,\s*/)
      default_options = {
        sub_population: :clients,
        coc_codes: site_coc_codes,
        comparison_pattern: :prior_year,
      }
      return { filters: default_options } unless params[:filters].present?

      filters = params.permit(filters: @filter.known_params)
      filters[:filters][:coc_codes] ||= site_coc_codes
      # Enforce comparison
      filters[:filters][:comparison_pattern] = :prior_year
      filters
    end
    helper_method :filter_params

    private def report_scope
      report_class.visible_to(current_user)
    end

    private def set_report
      @report = report_class.find(params[:id].to_i)
    end

    private def report_class
      AllNeighborsSystemDashboard::Report
    end

    private def filter_class
      ::Filters::FilterBase
    end
  end
end
