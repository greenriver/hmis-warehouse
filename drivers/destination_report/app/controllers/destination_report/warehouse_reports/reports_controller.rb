###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module DestinationReport::WarehouseReports
  class ReportsController < ApplicationController
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
          filename = "Destination - #{Time.current.to_s(:db)}.xlsx"
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
          filename = "Destination Support for #{@report.support_title(@key).gsub(',', '')} - #{Time.current.to_s(:db)}.xlsx"
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
      DestinationReport::Report
    end

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
          :coordinated_assessment_living_situation_homeless,
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
          destination_report_ids: [],
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
      # @pdf_export = pdf_export_source.new
    end

    private def pdf_export_source
      DestinationReport::DocumentExports::DestinationReportExport
    end
  end
end
