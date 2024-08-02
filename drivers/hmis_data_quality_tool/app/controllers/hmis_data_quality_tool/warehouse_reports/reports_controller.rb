###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisDataQualityTool::WarehouseReports
  class ReportsController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include ArelHelper
    include BaseFilters
    include HistoryFilter

    before_action :require_can_access_some_version_of_clients!, only: [:details, :items]
    before_action :set_report, only: [:show, :by_client, :by_chart, :destroy, :details, :items]
    before_action :set_pdf_export, only: [:show]
    before_action :set_chart_pdf_export, only: [:by_chart]
    before_action :set_excel_export, only: [:show]
    before_action :set_excel_by_client_export, only: [:by_client]

    def index
      reports = apply_view_filters(report_scope)
      @pagy, @reports = pagy(reports.diet.ordered)
      @report = report_class.new(user_id: current_user.id)
      @filter.default_project_type_codes = @report.default_project_type_codes
      previous_report = report_scope.where(user_id: current_user.id).last
      @filter.update(previous_report.options) if previous_report

      # Make sure the form will work
      filters
    end

    def show
      respond_to do |format|
        format.html {}
        format.xlsx do
          filename = "#{@report.title&.tr(' ', '-')}-By-Category-#{Date.current.strftime('%Y-%m-%d')}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def by_client
      @clients = @report.clients.order(:last_name, :first_name)
      @pivot_details = @report.pivot_details
      @pagy, @clients = pagy(@clients)
      respond_to do |format|
        format.html {}
        format.xlsx do
          filename = "#{@report.title&.tr(' ', '-')}-By-Client-#{Date.current.strftime('%Y-%m-%d')}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def by_chart
      @per_page_js = [
        'hmis_dq_tool_chart',
        'hmis_dq_tool_completeness',
        'hmis_dq_tool_time_to_enter',
        'hmis_dq_tool_time_in_enrollment',
      ]
    end

    def create
      @report = report_class.new(
        user_id: current_user.id,
        # For compatibility with HudReports::ReportInstance
        report_name: report_class.untranslated_title,
        manual: true,
        question_names: [],
      )
      @report.filter = @filter

      if @filter.valid?
        @report.save
        ::WarehouseReports::GenericReportJob.perform_later(
          user_id: current_user.id,
          report_class: @report.class.name,
          report_id: @report.id,
        )
        # Make sure the form will work
        filters
        respond_with(@report, location: @report.index_path)
      else
        @pagy, @reports = pagy(report_scope.ordered)
        set_view_filter
        filters
        render :index
      end
    end

    def destroy
      @report.destroy
      respond_with(@report, location: @report.index_path)
    end

    def details
      @key = @report.results_for_display[details_params[:category_name]][:reporting].keys.detect do |k|
        details_params[:key] == k.to_s
      end
      @category_name = @report.results_for_display.keys.detect { |m| m == details_params[:category_name] }
      @result = @report.results_for_display[@category_name][:reporting][@key]
      @comparison = @report.results_for_display[@category_name][:comparison][@key]
    end

    def items
      @key = @report.known_keys.detect do |k|
        details_params[:key] == k.to_s
      end

      @result = @report.result_from_key(@key)
      @items = @report.items_for(@key)
      respond_to do |format|
        format.html {}
        format.xlsx do
          title = "#{@result.category} #{@result.title}"
          filename = "#{sanitized_name(title)}-#{Date.current.to_fs(:db)}.xlsx"
          headers['Content-Type'] = GrdaWarehouse::DocumentExport::EXCEL_MIME_TYPE
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def sanitized_name(name)
      # See https://www.keynotesupport.com/excel-basics/worksheet-names-characters-allowed-prohibited.shtml
      name.gsub(/[',\*\/\\\?\[\]\:]/, '-').gsub(' - ', '-').gsub(' ', '-')
    end

    def details_params
      params.permit(:key)
    end
    helper_method :details_params

    private def set_report
      @report = report_class.find(params[:id].to_i)
    end

    private def set_pdf_export
      @pdf_export = HmisDataQualityTool::DocumentExports::ReportExport.new
    end

    private def set_chart_pdf_export
      @pdf_export = HmisDataQualityTool::DocumentExports::ReportChartPdfExport.new
    end

    private def set_excel_export
      @excel_export = HmisDataQualityTool::DocumentExports::ReportExcelExport.new
    end

    private def set_excel_by_client_export
      @excel_export = HmisDataQualityTool::DocumentExports::ReportByClientExcelExport.new
    end

    # Since this report uses the hud version of report instance, and it isn't STI
    # we need to limit to those with a report name matching this one
    private def report_scope
      report_class.
        where(report_name: report_class.untranslated_title).
        visible_to(current_user)
    end

    private def report_class
      HmisDataQualityTool::Report
    end

    private def set_filter
      @filter = filter_class.new(user_id: current_user.id, enforce_one_year_range: false, require_service_during_range: false)
      @filter.update(filter_params[:filters]) if filter_params[:filters].present?
    end

    def filter_params
      site_coc_codes = GrdaWarehouse::Config.default_site_coc_codes
      default_options = {
        sub_population: :clients,
        coc_codes: site_coc_codes,
        comparison_pattern: :prior_year,
      }
      return { filters: default_options } unless params[:filters].present?

      filters = params.permit(filters: @filter.known_params)
      filters[:filters][:coc_codes] ||= site_coc_codes
      filters
    end
    helper_method :filter_params

    private def filter_class
      ::Filters::HudFilterBase
    end

    private def path_for_clear_view_filter
      hmis_data_quality_tool_warehouse_reports_reports_path
    end
    helper_method :path_for_clear_view_filter

    private def flash_interpolation_options
      { resource_name: @report.title }
    end

    def formatted_cell(cell)
      return view_context.content_tag(:pre, JSON.pretty_generate(cell)) if cell.is_a?(Array) || cell.is_a?(Hash)
      return view_context.yes_no(cell) if cell.in?([true, false])

      cell
    end
    helper_method :formatted_cell
  end
end
