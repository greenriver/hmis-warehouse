###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module LongitudinalSpm::WarehouseReports
  class ReportsController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include ArelHelper
    include BaseFilters

    before_action :require_can_access_some_version_of_clients!, only: [:details]
    before_action :set_report, only: [:show, :destroy, :details]
    # before_action :set_pdf_export, only: [:show]

    def index
      @filter.default_project_type_codes = report_class.default_project_type_codes

      @pagy, @reports = pagy(report_scope.ordered)
      @report = report_class.new(user_id: current_user.id)
      previous_report = report_scope.last
      if previous_report
        @filter.update(previous_report.options)
      else
        @filter['project_type_codes'] = []
      end
      @filter.project_type_codes = report_class.default_project_type_codes if @filter.project_type_codes.blank?
      # Make sure the form will work
      filters
    end

    def show
      @results = @report.results.to_a
      respond_to do |format|
        format.html {}
        format.xlsx do
          filename = "#{@report.title&.tr(' ', '-')}-#{Date.current.strftime('%Y-%m-%d')}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def create
      @report = report_class.new(
        user_id: current_user.id,
        options: @filter.to_h,
      )

      if @filter.valid?
        @report.save
        ::WarehouseReports::GenericReportJob.perform_later(
          user_id: current_user.id,
          report_class: @report.class.name,
          report_id: @report.id,
        )
        # Make sure the form will work
        filters
        respond_with(@report, location: longitudinal_spm_warehouse_reports_reports_path)
      else
        @pagy, @reports = pagy(report_scope.ordered)
        filters
        render :index
      end
    end

    def destroy
      @report.destroy
      respond_with(@report, location: longitudinal_spm_warehouse_reports_reports_path)
    end

    def details_params
      params.permit(
        :spm_id,
        :measure,
        :table,
        :cell,
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
      LongitudinalSpm::Report
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
      filters[:filters][:enforce_one_year_range] = false
      filters[:filters][:start] = filters[:filters][:end].to_date - 1.years
      filters
    end
    helper_method :filter_params

    # private def set_pdf_export
    #   @pdf_export = LongitudinalSpm::DocumentExports::ReportExport.new
    # end

    private def filter_class
      ::Filters::HudFilterBase
    end

    private def flash_interpolation_options
      { resource_name: @report.title }
    end
  end
end
