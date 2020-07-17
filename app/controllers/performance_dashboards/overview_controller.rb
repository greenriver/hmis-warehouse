###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboards
  class OverviewController < BaseController
    before_action :set_filter
    before_action :set_report
    before_action :set_key, only: [:details]
    before_action :set_pdf_export

    def index
    end

    def filters
      @sections = @report.control_sections
      chosen = params[:filter_section_id]
      if chosen
        @chosen_section = @sections.detect do |section|
          section.id == chosen
        end
      end
      @modal_size = :xl if @chosen_section.nil?
    end

    def details
      @options = option_params[:filters]
      @breakdown = params.dig(:filters, :breakdown)
      @sub_key = params.dig(:filters, :sub_key)

      respond_to do |format|
        format.xlsx do
          render(
            xlsx: 'details',
            filename: "#{@report.support_title(@options)} - #{Time.current.to_s.delete(',')}.xlsx",
          )
        end
        format.html
      end
    end

    private def option_params
      params.permit(
        filters: [
          :key,
          :sub_key,
          :age,
          :gender,
          :household,
          :veteran,
          :sub_population,
          :race,
          :ethnicity,
          :project_type,
          :coc,
          :breakdown,
        ],
      )
    end

    private def multiple_project_types?
      true
    end
    helper_method :multiple_project_types?

    private def include_comparison_pattern?
      true
    end
    helper_method :include_comparison_pattern?

    private def set_report
      @report_variant = 'sparse'
      @report = report_class.new(@filter)
      if @report.include_comparison?
        @comparison = report_class.new(@comparison_filter)
      else
        @comparison = @report
      end
    end

    private def filter_class
      ::Filters::PerformanceDashboard
    end

    private def set_key
      @key = report_class.detail_method(params.dig(:filters, :key))
    end

    private def set_pdf_export
      @pdf_export = GrdaWarehouse::DocumentExports::ClientPerformanceExport.new
    end

    private def report_class
      PerformanceDashboards::Overview
    end
  end
end
