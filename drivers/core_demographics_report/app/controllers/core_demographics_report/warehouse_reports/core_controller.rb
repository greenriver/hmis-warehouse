###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CoreDemographicsReport::WarehouseReports
  class CoreController < ApplicationController
    include WarehouseReportAuthorization
    include PjaxModalController
    include ArelHelper
    include BaseFilters

    before_action :set_report

    def index
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
      @section = @report.class.available_chart_types.detect do |m|
        m == params.require(:partial).underscore
      end
      @section = 'overall' if @section.blank? && params.require(:partial) == 'overall'

      raise 'Rollup not in allowlist' unless @section.present?

      @section = @report.section_subpath + @section
      render partial: @section, layout: false if request.xhr?
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
        ],
      )
    end
    helper_method :filter_params

    private def filter_class
      ::Filters::FilterBase
    end
  end
end
