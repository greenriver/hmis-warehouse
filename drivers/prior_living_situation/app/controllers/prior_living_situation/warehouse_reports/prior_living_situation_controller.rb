###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module PriorLivingSituation::WarehouseReports
  class PriorLivingSituationController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include ArelHelper
    include BaseFilters

    before_action :require_can_view_clients, only: [:detail]
    before_action :set_report
    before_action :set_pdf_export

    def index
      respond_to do |format|
        format.html {}
        format.xlsx do
          filename = "Prior Living Situation - #{Time.current.to_fs(:db)}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def details
      @key = params[:key]
      @sub_key = params[:sub_key]
      # Sometimes the details page is called with no arguments, probably because the user was logged out
      if @key.blank?
        redirect_to prior_living_situation_warehouse_reports_prior_living_situation_index_path
        return
      end
      respond_to do |format|
        format.html {}
        format.xlsx do
          filename = "Prior Living Situation Support for #{@report.support_title(@key).gsub(',', '')} - #{Time.current.to_fs(:db)}.xlsx"
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
      PriorLivingSituation::PriorLivingSituationReport
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
      # @pdf_export = pdf_export_source.new
    end

    private def pdf_export_source
      PriorLivingSituation::DocumentExports::PriorLivingSituationExport
    end
  end
end
