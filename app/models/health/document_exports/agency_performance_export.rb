###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health::DocumentExports
  class AgencyPerformanceExport < ::Health::DocumentExport
    def authorized?
      user.can_view_aggregate_health?
    end

    protected def report
      report_params = params.with_indifferent_access || {}
      end_date = report_params[:end_date].to_date
      start_date = report_params[:start_date].to_date
      @report ||= report_class.new(range: start_date..end_date)
      @agencies = @report.agency_counts
      @totals = @report.total_counts
      @report
    end

    protected def view_assigns
      {
        report: report,
        agencies: @agencies,
        totals: @totals,
        pdf: true,
      }
    end

    def params
      query_string.present? ? Rack::Utils.parse_nested_query(query_string) : {}
    end

    def perform
      with_status_progression do
        template_file = 'warehouse_reports/health/agency_performance/index_pdf'
        layout = 'layouts/healthcare_report'

        html = PdfGenerator.html(
          controller: controller_class,
          template: template_file,
          layout: layout,
          user: user,
          assigns: view_assigns,
        )
        PdfGenerator.new.perform(
          html: html,
          file_name: "Partner Dashboard #{DateTime.current.to_s(:db)}",
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    def download_title
      'Partner Dashboard Report'
    end

    protected def report_class
      Health::AgencyPerformance
    end

    private def controller_class
      WarehouseReports::Health::AgencyPerformanceController
    end

    class AgencyPerformanceExportTemplate < PdfExportTemplateBase
      def show_client_details?
        false
      end
    end
  end
end
