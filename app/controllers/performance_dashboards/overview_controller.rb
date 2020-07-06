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

    def index
      @pdf_export = pdf_export
      respond_to do |format|
        format.pdf do
          @pdf = true
          render_pdf
        end
        format.html do
          if params[:debug_pdf]
            @pdf = true
            render inline: pdf_html
          end
        end
      end
    end

    private def section_subpath
      'performance_dashboards/overview/'
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

    private def default_project_types
      GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING.keys
    end

    private def set_report
      @report = PerformanceDashboards::Overview.new(@filter)
      if @report.include_comparison?
        @comparison = PerformanceDashboards::Overview.new(@comparison_filter)
      else
        @comparison = @report
      end
    end

    private def set_key
      @key = PerformanceDashboards::Overview.detail_method(params.dig(:filters, :key))
    end

    private def default_comparison_pattern
      :no_comparison_period
    end

    private def render_pdf
      file_name = "Performance Overview #{DateTime.current.to_s(:db)}"
      send_data pdf, filename: "#{file_name}.pdf", type: 'application/pdf', disposition: 'attachment'
    end

    protected def pdf
      grover_options = {
        display_url: root_url,
        displayHeaderFooter: true,
        headerTemplate: '<h2>Header</h2>',
        footerTemplate: '<h6 class="text-center">Footer</h6>',
        timeout: 50_000,
        format: 'Letter',
        emulate_media: 'print',
        margin: {
          top: '.5in',
          bottom: '.5in',
          left: '.4in',
          right: '.4in',
        },
        debug: {
          # headless: false,
          # devtools: true
        },
      }

      Grover.new(pdf_html, grover_options).to_pdf
    end

    private def pdf_html
      template = 'performance_dashboards/overview/index_pdf'
      render_to_string({ template: template, layout: false })
    end

    private def pdf_export
      DocumentExports::PerformanceDashboardExport.new
    end
  end
end
