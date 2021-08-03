###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CoreDemographicsReport::WarehouseReports
  class CoreController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include ArelHelper
    include BaseFilters
    extend BackgroundRenderAction

    before_action :require_can_view_clients, only: [:detail]
    before_action :set_report
    before_action :set_pdf_export

    background_render_action :render_section, ::BackgroundRender::CoreDemographicsReportJob do
      {
        partial: params.require(:partial).underscore,
        filters: @filter.for_params[:filters].to_json,
        user_id: current_user.id,
      }
    end

    def index
      @pdf_export = CoreDemographicsReport::DocumentExports::CoreDemographicsExport.new
      respond_to do |format|
        format.html {}
        format.xlsx do
          filename = "Core Demographics - #{Time.current.to_s(:db)}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def details
      @key = params[:key]
      @sub_key = params[:sub_key]
      respond_to do |format|
        format.html {}
        format.xlsx do
          filename = "Core Demographics Support for #{@report.support_title(@key).gsub(',', '')} - #{Time.current.to_s(:db)}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
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
      CoreDemographicsReport::Core
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
      params.permit(filters: @filter.known_params)
    end
    helper_method :filter_params

    private def filter_class
      ::Filters::FilterBase
    end

    private def set_pdf_export
      @pdf_export = CoreDemographicsReport::DocumentExports::CoreDemographicsExport.new
    end
  end
end
