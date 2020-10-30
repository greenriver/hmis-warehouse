###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CoreDemographicsReport::WarehouseReports
  class CoreController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include ArelHelper
    include BaseFilters

    before_action :set_report
    before_action :set_pdf_export

    def index
      @pdf_export = CoreDemographicsReport::DocumentExports::CoreDemographicsExport.new
      respond_to do |format|
        format.html {}
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=Core Demographics - #{Time.current.to_s(:db)}.xlsx"
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

    def breakdown
      @breakdown ||= params[:breakdown]&.to_sym || :none
    end
    helper_method :breakdown

    def filter_params
      params.permit(
        filters: [
          :start,
          :end,
          :comparison_pattern,
          :household_type,
          :hoh_only,
          :sub_population,
          :chronic_status,
          coc_codes: [],
          project_types: [],
          project_type_codes: [],
          veteran_statuses: [],
          age_ranges: [],
          genders: [],
          races: [],
          ethnicities: [],
          data_source_ids: [],
          organization_ids: [],
          project_ids: [],
          funder_ids: [],
          project_group_ids: [],
          prior_living_situation_ids: [],
          destination_ids: [],
          disabilities: [],
          indefinite_disabilities: [],
          dv_status: [],
        ],
      )
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
