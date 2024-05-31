###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AllNeighborsSystemDashboard::WarehouseReports
  class ReportsController < ApplicationController
    include WarehouseReportAuthorization
    include BaseFilters

    before_action :set_report, except: [:index, :create]
    before_action :require_can_publish_reports!, only: [:raw, :update]

    def index
      @pagy, @reports = pagy(report_scope.ordered)
      @report = report_class.new(user_id: current_user.id)
      @filter.default_project_type_codes = @report.default_project_type_codes
      previous_report = report_scope.where(user_id: current_user.id).last
      @filter.update(previous_report.options) if previous_report

      # Make sure the form will work
      filters
    end

    def create
      @report = report_class.new(
        user_id: current_user.id,
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
        respond_with(@report, location: all_neighbors_system_dashboard_warehouse_reports_reports_path)
      else
        @pagy, @reports = pagy(report_scope.ordered)
        filters
        render :index
      end
    end

    def show
      @per_page_js = [
        'all_neighbors_system_dashboard_filters',
        'all_neighbors_system_dashboard_stack',
        'all_neighbors_system_dashboard_quarters',
        'all_neighbors_system_dashboard_line',
        'all_neighbors_system_dashboard_donut',
        'all_neighbors_system_dashboard_bar',
      ]
      respond_to do |format|
        format.html {}
        # format.xlsx do
        #   file = @report.result_file
        #   @report.attach_rendered_xlsx if file.download.nil? # Generate the XLSX if it is missing
        #   filename = "#{@report.title&.tr(' ', '-')}-#{Date.current.strftime('%Y-%m-%d')}.xlsx"
        #   send_data file.download, filename: filename, type: file.content_type, disposition: 'attachment'
        # end
      end
    end

    def internal
      @internal = true
    end

    def destroy
      @report.destroy
      respond_with(@report, location: all_neighbors_system_dashboard_warehouse_reports_reports_path)
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

    def raw
      render(layout: 'external')
    end

    def debug
    end

    def filter_params
      filters = params.permit(filters: @filter.known_params)

      filters
    end
    helper_method :filter_params

    def publish_params
      params.require(:public_report).
        permit(:path, :published_url, :unpublish)
    end

    def css_namespace(tab_id, name)
      "all-neighbors__#{tab_id}__#{name}"
    end
    helper_method :css_namespace

    def filter_id(tab_id, name)
      "#{css_namespace(tab_id, name)}__filter"
    end
    helper_method :filter_id

    def chart_id(tab_id, name, item = nil)
      id = "#{css_namespace(tab_id, name)}__chart"
      id = "#{id}__#{item}" if item.present?
      id
    end
    helper_method :chart_id

    def legend_id(tab_id, name)
      chart_id(tab_id, name, 'legend')
    end
    helper_method :legend_id

    def table_id(tab_id, name)
      "#{css_namespace(tab_id, name)}__table"
    end
    helper_method :table_id

    def filter_label_id(tab_id, name)
      "#{css_namespace(tab_id, name)}__filter_label"
    end
    helper_method :filter_label_id

    def render_path(file_name)
      @internal ? "all_neighbors_system_dashboard/warehouse_reports/reports/#{file_name}" : file_name
    end
    helper_method :render_path

    private def flash_interpolation_options
      { resource_name: @report.title }
    end

    private def report_scope
      report_class.visible_to(current_user)
    end

    private def set_report
      @report = report_class.find(params[:id].to_i)
    end

    private def report_class
      AllNeighborsSystemDashboard::Report
    end

    private def set_filter
      @filter = filter_class.new(user_id: current_user.id)
      @filter.update(enforce_one_year_range: false)
      @filter.set_from_params(filter_params[:filters]) if filter_params[:filters].present?
      @comparison_filter = @filter.to_comparison
    end

    private def filter_class
      ::Filters::HudFilterBase
    end

    def path_to_report
      all_neighbors_system_dashboard_warehouse_reports_report_path(@report)
    end
    helper_method :path_to_report
  end
end
