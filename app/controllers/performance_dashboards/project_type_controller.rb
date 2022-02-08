###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboards
  class ProjectTypeController < OverviewController
    include AjaxModalRails::Controller
    before_action :set_report
    before_action :set_key, only: [:details]
    before_action :set_pdf_export

    def index
    end

    private def section_subpath
      'performance_dashboards/project_type/'
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
      render xlsx: 'xlsx_download', filename: "#{@report.project_type_title} Performance".truncate(31)
    end

    private def option_params
      params.permit(
        filters: [
          :key,
          :sub_key,
          :living_situation,
          :destination,
          :length_of_time,
          :returns,
          :breakdown,
          :coordinated_assessment_living_situation_homeless,
        ],
      )
    end

    private def set_report
      @report = PerformanceDashboards::ProjectType.new(@filter)
      if @report.include_comparison?
        @comparison = PerformanceDashboards::ProjectType.new(@comparison_filter)
      else
        @comparison = @report
      end
    end

    private def set_key
      @key = PerformanceDashboards::ProjectType.detail_method(params.dig(:filters, :key))
    end

    private def filter_class
      ::Filters::PerformanceDashboardByProjectType
    end

    private def set_pdf_export
      @pdf_export = GrdaWarehouse::DocumentExports::ProjectTypePerformanceExport.new
    end
  end
end
