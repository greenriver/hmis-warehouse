###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMeasurement::WarehouseReports
  class ReportsController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include ArelHelper
    include BaseFilters

    before_action :require_can_access_some_version_of_clients!, only: [:details]
    before_action :set_report, only: [:show, :destroy]

    def index
      @reports = report_scope.ordered.
        page(params[:page]).per(25)
      @report = report_class.new(user_id: current_user.id)
      previous_report = report_scope.last
      if previous_report
        @filter.update(previous_report.options)
      else
        @filter['project_type_codes'] = @report.default_project_types
      end
      # Make sure the form will work
      filters
    end

    def show
    end

    def create
      @report = report_class.new(
        user_id: current_user.id,
      )
      @report.filter = @filter
      @report.save
      ::WarehouseReports::GenericReportJob.perform_later(
        user_id: current_user.id,
        report_class: @report.class.name,
        report_id: @report.id,
      )
      # Make sure the form will work
      filters
      respond_with(@report, location: performance_measurement_warehouse_reports_reports_path)
    end

    def destroy
      @report.destroy
      respond_with(@report, location: performance_measurement_warehouse_reports_reports_path)
    end

    def details
      @report = report_class.find(params[:report_id].to_i)
      @key = params[:key].to_sym
    end

    def details_params
      params.permit(
        :key,
      )
    end
    helper_method :details_params

    private def set_report
      @report = report_class.find(params[:id].to_i)
    end

    private def report_scope
      report_class.visible_to(current_user)
    end

    private def report_class
      PerformanceMeasurement::Report
    end

    def filter_params
      site_coc_codes = GrdaWarehouse::Config.get(:site_coc_codes).presence&.split(/,\s*/)
      default_options = {
        sub_population: :clients,
        coc_codes: site_coc_codes,
      }
      return { filters: default_options } unless params[:filters].present?

      filters = params.permit(filters: @filter.known_params)
      filters[:coc_codes] ||= site_coc_codes
      filters
    end
    helper_method :filter_params

    private def filter_class
      ::Filters::FilterBase
    end

    private def flash_interpolation_options
      { resource_name: @report.title }
    end
  end
end
