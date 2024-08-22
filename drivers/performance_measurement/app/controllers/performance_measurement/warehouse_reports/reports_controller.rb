###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMeasurement::WarehouseReports
  class ReportsController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include ArelHelper
    include BaseFilters
    include ActionView::Helpers::NumberHelper

    before_action :require_can_access_some_version_of_clients!, only: [:clients]
    before_action :require_my_project!, only: [:clients]
    before_action :require_can_publish_reports!, only: [:raw, :update]
    before_action :set_report, except: [:index, :create, :details, :clients]
    before_action :set_pdf_export, only: [:show]

    @include_in_published_version = false
    @include_in_summary_only_version = false

    def index
      @filter.default_project_type_codes = report_class.default_project_type_codes
      @filter.comparison_pattern = :prior_fiscal_year
      PerformanceMeasurement::Goal.ensure_default
      @pagy, @reports = pagy(report_scope.ordered)
      @report = report_class.new(user_id: current_user.id)
      previous_report = report_scope.where(user_id: current_user.id).last
      @filter.update(previous_report.options) if previous_report

      # Make sure the form will work
      filters
    end

    def show
      # Used for testing PDF generation
      # render 'show_pdf', layout: 'layouts/performance_report'
      @default_goal = PerformanceMeasurement::Goal.default_goal
    end

    def create
      @report = report_class.new(
        user_id: current_user.id,
      )
      @report.filter = @filter
      @report.save
      @report.update_goal_configuration!
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

    def update
      path = publish_params[:path]
      if publish_params&.key?(:path)
        @report.update(path: path)
        respond_with(@report, location: path_to_report)
      elsif publish_params[:unpublish] == @report.generate_publish_url
        @report.unpublish!
        flash[:notice] = 'Report has been unpublished.'
        respond_with(@report, location: path_to_report)
      elsif publish_params[:published_url].present?
        @report.delay.publish!(current_user.id)
        flash[:notice] = 'Report publishing queued, please check the public link in a few minutes.'
        respond_with(@report, location: path_to_report)
      else
        redirect_to(action: :edit)
      end
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
          filename = "#{@report.detail_title_for(@key).tr(' ', '-').tr(',', '')}-#{Date.current.to_fs(:db)}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def equity_analysis
      @equity_filters = params[:equity_filters]
      @analysis_builder = PerformanceMeasurement::EquityAnalysis::Builder.new(@equity_filters, @report, current_user)
      if @equity_filters.present?
        # if there are filters set errors
        flash[:error] = @analysis_builder.valid? ? '' : 'There was an error building the equity analysis.'
      end
      render :show
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

      filters = params.permit(filters: report_class.known_params)
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

    def formatted_cell(cell, key)
      return view_context.content_tag(:pre, JSON.pretty_generate(cell)) if cell.is_a?(Array) || cell.is_a?(Hash)
      return view_context.yes_no(cell) if cell.in?([true, false])

      case key.to_s
      when /prior_living_situation$/
        HudUtility2024.living_situation(cell)
      when /_destination$/
        HudUtility2024.destination(cell)
      when /_days_/
        number_with_delimiter(cell)
      else
        cell
      end
    end
    helper_method :formatted_cell

    def path_to_report
      performance_measurement_warehouse_reports_report_path(@report)
    end
    helper_method :path_to_report

    def publish_params
      params.require(:public_report).
        permit(:path, :published_url, :unpublish)
    end
  end
end
