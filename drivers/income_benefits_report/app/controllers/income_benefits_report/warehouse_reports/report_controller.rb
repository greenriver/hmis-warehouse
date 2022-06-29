###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module IncomeBenefitsReport::WarehouseReports
  class ReportController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include ArelHelper
    include BaseFilters

    before_action :require_can_access_some_version_of_clients!, only: [:details]
    before_action :set_report, only: [:show, :destroy, :details]
    before_action :set_pdf_export

    def index
      @pagy, @reports = pagy(report_scope.ordered)
      @report = report_class.new(user_id: current_user.id)
      @report.filter = @filter

      previous_report = report_scope.last
      if previous_report&.options&.key?('filters')
        @filter.update(previous_report.options['filters'])
      else
        @filter['project_type_codes'] = @report.default_project_types
      end

      # Make sure the form will work
      filters
    end

    def create
      @report = report_class.new(
        user_id: current_user.id,
        report_date_range: @filter.date_range_words,
        comparison_date_range: @filter.comparison_range_words,
      )
      @report.filter = @filter
      @report.save
      ::WarehouseReports::GenericReportJob.perform_later(
        user_id: current_user.id,
        report_class: @report.class.name,
        report_id: @report.id,
      )
      respond_with(@report, location: income_benefits_report_warehouse_reports_report_index_path)
    end

    def destroy
      @report.destroy
      respond_with(@report, location: income_benefits_report_warehouse_reports_report_index_path)
    end

    def details
      @key = params[:key].to_sym
      @comparison = params[:comparison] == 'true'
      @report = @report.to_comparison if @comparison
      @filter = @filter.to_comparison if @comparison
      respond_to do |format|
        format.html {}
        format.xlsx {}
      end
    end

    def breakdown
      @breakdown ||= params[:breakdown]&.to_sym || :none
    end
    helper_method :breakdown

    private def set_report
      @report = report_class.find(params[:id].to_i)
      if @report.include_comparison?
        @comparison = @report.to_comparison
      else
        @comparison = @report
      end
    end

    private def report_scope
      report_class.visible_to(current_user)
    end

    private def report_class
      IncomeBenefitsReport::Report
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
      @pdf_export = IncomeBenefitsReport::DocumentExports::IncomeBenefitsExport.new
    end

    private def flash_interpolation_options
      { resource_name: @report.title }
    end
  end
end
