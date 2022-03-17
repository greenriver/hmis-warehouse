###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
    # before_action :set_pdf_export

    background_render_action(:render_section, ::BackgroundRender::DisabilitySummaryJob) do
      {
        partial: params.require(:partial).underscore,
        filters: @filter.for_params[:filters].to_json,
        user_id: current_user.id,
      }
    end

    def index
      respond_to do |format|
        format.html {}
        # format.xlsx do
        #   filename = "Client Analysis - #{Time.current.to_s(:db)}.xlsx"
        #   headers['Content-Disposition'] = "attachment; filename=#{filename}"
        # end
      end
    end

    def details
      respond_to do |format|
        format.html {}
        format.xlsx do
          filename = "Client Support for #{@report.support_title(@key).gsub(',', '')} - #{Time.current.to_s(:db)}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def breakdowns
      # This is needed when generating the PDF
      # if @report.blank?
      #   set_filter
      #   set_report
      # end
      @breakdowns ||= {}.tap do |bd|
        bd[:x] ||= params[:x_breakdown]&.to_sym || @report.available_breakdowns.keys.first
        bd[:y] ||= params[:y_breakdown]&.to_sym || @report.available_breakdowns.keys.second
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
      @section = @report.class.available_section_types.detect do |m|
        m == params.require(:partial).underscore
      end
      @section = 'overall' if @section.blank? && params.require(:partial) == 'overall'

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
      params.permit(filter: filter_class.new.known_params)
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
