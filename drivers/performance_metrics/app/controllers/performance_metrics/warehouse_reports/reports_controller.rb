###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMetrics::WarehouseReports
  class ReportsController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include ArelHelper
    include BaseFilters

    before_action :require_can_access_some_version_of_clients!, only: [:details]
    before_action :set_report, only: [:show, :destroy, :details]
    before_action :set_pdf_export

    def index
      @reports = report_scope.ordered.
        page(params[:page]).per(25)
      # @filter = filter_class.new(user_id: current_user.id)
      # @filter.set_from_params(filter_params) if filter_params.present?
      @report = report_class.new(user_id: current_user.id)
      @report.filter = @filter
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
      respond_with(@report, location: performance_metrics_warehouse_reports_reports_path)

    end

    def destroy
      @report.destroy
      respond_with(@report, location: performance_metrics_warehouse_reports_reports_path)
    end

    def details
      @key = params[:key].to_sym
      @comparison = params[:comparison] == 'true'
      respond_to do |format|
        format.html {}
        format.xlsx {}
      end
    end

    def breakdown
      @breakdown ||= params[:breakdown]&.to_sym || :none
    end
    helper_method :breakdown

    private def set_report
      @report = report_class.find(params[:id].to_i)
    end

    private def report_scope
      report_class.visible_to(current_user)
    end

    private def report_class
      PerformanceMetrics::Report
    end

    def filter_params
      return { filters: { comparison_pattern: :prior_year, sub_population: :clients }} unless params[:filters].present?

      params.permit(filters: @filter.known_params)
    end
    helper_method :filter_params

    private def filter_class
      ::Filters::FilterBase
    end

    private def set_pdf_export
      @pdf_export = pdf_export_source.new
    end

    private def pdf_export_source
      PerformanceMetrics::DocumentExports::ReportExport
    end

    private def flash_interpolation_options
      { resource_name: @report.title }
    end
  end
end
