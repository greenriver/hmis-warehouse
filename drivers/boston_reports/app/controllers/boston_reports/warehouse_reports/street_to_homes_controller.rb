###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BostonReports::WarehouseReports
  class StreetToHomesController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include ArelHelper
    include BaseFilters
    extend BackgroundRenderAction

    before_action :require_can_view_clients, only: [:detail]
    before_action :set_report
    before_action :set_pdf_export

    background_render_action(:render_section, ::BackgroundRender::StreetToHomeJob) do
      {
        partial: params.require(:partial).underscore,
        filters: @filter.for_params[:filters].to_json,
        user_id: current_user.id,
      }
    end

    def index
      @pdf_export = BostonReports::DocumentExports::StreetToHomePdfExport.new
      respond_to do |format|
        format.html {}
        format.xlsx do
          filename = "Street to Home - #{Time.current.to_s(:db)}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def details
      @detail_options = {}
      @detail_options[:sets] = params[:sets] if (@report.clients.keys & params[:sets]).present?
      @clients = @report.client_details(params[:sets])
      respond_to do |format|
        format.html {}
        format.xlsx do
          render xlsx: 'details', filename: "Street2Home-Details-#{@detail_options[:sets].join('-')}.xlsx"
        end
      end
    end

    private def set_report
      @report = report_class.new(@filter)
      if @report.include_comparison?
        @comparison = report_class.new(@comparison_filter)
      else
        @comparison = @report
      end
    end

    private def report_class
      BostonReports::StreetToHome
    end

    def section
      @section = @report.class.available_section_types.detect do |m|
        m == params.require(:partial).underscore
      end
      @section = 'dashboard' if @section.blank? && params.require(:partial) == 'dashboard'

      raise 'Rollup not in allowlist' unless @section.present?

      if @report.section_ready?(@section)
        @section = @report.section_subpath + @section
        render partial: @section, layout: false if request.xhr?
      else
        render_to_string(partial: @section, layout: false)
        render status: :accepted, plain: 'Loading'
      end
    end

    def filter_params
      params.permit(filters: @filter.known_params)
    end
    helper_method :filter_params

    private def filter_class
      ::Filters::FilterBase
    end

    private def set_pdf_export
      @pdf_export = BostonReports::DocumentExports::StreetToHomePdfExport.new
    end
  end
end
