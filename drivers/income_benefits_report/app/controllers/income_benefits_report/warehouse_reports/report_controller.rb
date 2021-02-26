###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module IncomeBenefitsReport::WarehouseReports
  class ReportController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include ArelHelper
    include BaseFilters

    before_action :require_can_view_clients, only: [:detail]
    before_action :set_report, only: [:show, :destroy]
    before_action :set_pdf_export

    def index
      @reports = report_scope.ordered.
        page(params[:page]).per(25)
      # @filter = filter_class.new(user_id: current_user.id)
      # @filter.set_from_params(filter_params) if filter_params.present?
      @report = report_class.new(user_id: current_user.id)
      @report.filter = @filter
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

    def section
      @section = @report.class.available_section_types.detect do |m|
        m == params.require(:partial).underscore
      end
      @section = 'overall' if @section.blank? && params.require(:partial) == 'overall'

      raise 'Unknown section' unless @section.present?

      if @report.section_ready?(@section)
        @section = @report.section_subpath + @section
        layout = {}
        layout = { layout: false } if request.xhr?
        render({ partial: @section }.merge(layout))
      else
        render_to_string(partial: @section, layout: false)
        render status: :accepted, plain: 'Loading'
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
