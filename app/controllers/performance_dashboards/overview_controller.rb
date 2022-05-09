###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboards
  class OverviewController < BaseController
    before_action :set_report
    before_action :set_key, only: [:details]
    before_action :set_pdf_export

    def index
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

    def download
      render xlsx: 'xlsx_download', filename: "#{@report.performance_type} Performance.xlsx"
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
          :lot_homeless,
          :breakdown,
          :coordinated_assessment_living_situation_homeless,
          :inactivity_days,
        ],
      )
    end

    private def set_report
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
