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
        respond_with(@report, location: all_neighbors_system_dashboard_warehouse_reports_all_neighbors_system_dashboards_path)
      else
        @pagy, @reports = pagy(report_scope.ordered)
        filters
        render :index
      end
    end

    def show
      respond_to do |format|
        # format.html {}
        format.xlsx do
          @sheets = @report.sheets
          filename = "#{@report.title&.tr(' ', '-')}-#{Date.current.strftime('%Y-%m-%d')}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def destroy
      @report.destroy
      respond_with(@report, location: all_neighbors_system_dashboard_warehouse_reports_all_neighbors_system_dashboards_path)
    end

    def filter_params
      filters = params.permit(filters: @filter.known_params)

      filters
    end
    helper_method :filter_params

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

    private def filter_class
      ::Filters::FilterBase
    end
  end
end
