###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AnalysisTool::WarehouseReports
  class AnalysisToolController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include ArelHelper
    include BaseFilters
    extend BackgroundRenderAction

    before_action :require_can_view_clients, only: [:detail]
    before_action :set_report

    background_render_action(:render_section, ::BackgroundRender::AnalysisToolJob) do
      {
        filters: @filter.for_params[:filters].to_json,
        user_id: current_user.id,
        row_breakdown: breakdowns[:row],
        col_breakdown: breakdowns[:col],
      }
    end

    def index
      @report.breakdowns = breakdowns
      respond_to do |format|
        format.html {}
        format.xlsx do
          filename = "Client Analysis - #{Time.current.to_fs(:db)}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def details
      @report.breakdowns = breakdowns
      respond_to do |format|
        format.html {}
        format.xlsx do
          filename = "#{@report.support_title(params).gsub(',', '')} - #{Time.current.to_fs(:db)}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def breakdowns
      @breakdowns ||= {}.tap do |bd|
        bd[:row] ||= params[:row_breakdown]&.to_sym || @report.breakdowns[:row]
        bd[:col] ||= params[:col_breakdown]&.to_sym || @report.breakdowns[:col]
      end
    end
    helper_method :breakdowns

    private def set_report
      @report = report_class.new(@filter)
    end

    private def report_class
      AnalysisTool::Report
    end

    def section
      @report.breakdowns = breakdowns
      @section = 'table'

      if @report.section_ready?(@section)
        @section = @report.section_subpath + @section
        render partial: @section, layout: false if request.xhr?
      else
        render_to_string(partial: @section, layout: false)
        render status: :accepted, plain: 'Loading'
      end
    end

    def filter_params
      params.permit(filters: filter_class.new.known_params)
    end
    helper_method :filter_params

    private def filter_class
      ::Filters::FilterBase
    end

    # private def set_pdf_export
    #   @pdf_export = pdf_export_source.new
    # end

    # private def pdf_export_source
    #   AnalysisTool::DocumentExports::ReportExport
    # end
  end
end
