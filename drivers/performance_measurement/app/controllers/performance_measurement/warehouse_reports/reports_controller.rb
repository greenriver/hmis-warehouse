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

    before_action :require_can_access_some_version_of_clients!, only: [:details, :clients]
    before_action :require_my_project!, only: [:clients]
    before_action :set_report, only: [:show, :destroy]
    before_action :set_pdf_export, only: [:show]

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
      # Used for testing PDF generation
      # render 'show_pdf', layout: 'layouts/performance_report'
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

    def clients
      @report = report_class.find(params[:report_id].to_i)
      @key = params[:key].to_sym
      respond_to do |format|
        format.html {}
        format.xlsx do
          filename = "#{@report.detail_title_for(@key).tr(' ', '-')}-#{Date.current.to_s(:db)}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
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
        enforce_one_year_range: false,
      }
      return { filters: default_options } unless params[:filters].present?

      filters = params.permit(filters: @filter.known_params)
      filters[:filters][:coc_codes] ||= site_coc_codes
      filters[:filters][:start] = filters[:filters][:end].to_date - 1.years + 1.days
      filters[:filters][:enforce_one_year_range] = false
      filters
    end
    helper_method :filter_params

    private def filter_class
      ::Filters::FilterBase
    end

    private def flash_interpolation_options
      { resource_name: @report.title }
    end

    private def require_my_project!
      @report = report_class.find(params[:report_id].to_i)
      @key = params[:key].to_sym
      @project = @report.my_projects(current_user, @key)[params[:project_id].to_i]

      not_authorized! unless @project.present?
    end

    private def set_pdf_export
      @pdf_export = PerformanceMeasurement::DocumentExports::ReportExport.new
    end

    def formatted_cell(cell)
      return view_context.content_tag(:pre, JSON.pretty_generate(cell)) if cell.is_a?(Array) || cell.is_a?(Hash)
      return view_context.yes_no(cell) if cell.in?([true, false])

      cell
    end
    helper_method :formatted_cell
  end
end
