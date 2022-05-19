###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
      @pagy, @reports = pagy(report_scope.ordered)
      @report = report_class.new(user_id: current_user.id)
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
      @sub_key = params[:sub_key].to_sym
      @comparison = @report.include_comparison? && params[:index] == '0'
      @headers = PerformanceMetrics::Client.detail_headers
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
      # because some of the sub-reports require coc_codes, we need to make sure those are set, even
      # if we can't set them manually (non-multi-coc installation)
      site_coc_codes = GrdaWarehouse::Config.get(:site_coc_codes).presence&.split(/,\s*/)
      default_options = {
        comparison_pattern: :prior_year,
        sub_population: :clients,
        coc_codes: site_coc_codes,
      }
      return { filters: default_options } unless params[:filters].present?

      filters = params
      filters[:filters][:coc_codes] = site_coc_codes if filters[:filters][:coc_codes]&.reject(&:blank?).blank?
      filters.permit(filters: @filter.known_params)
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

    def formatted_cell(cell)
      return view_context.content_tag(:pre, JSON.pretty_generate(cell)) if cell.is_a?(Array) || cell.is_a?(Hash)

      cell
    end
    helper_method :formatted_cell
  end
end
