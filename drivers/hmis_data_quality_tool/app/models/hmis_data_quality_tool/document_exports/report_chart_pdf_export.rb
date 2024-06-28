###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisDataQualityTool::DocumentExports
  class ReportChartPdfExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    def authorized?
      user.can_view_any_reports? && report_class.viewable_by(user)
    end

    protected def report
      @report ||= report_class.find(params['id'])
    end

    protected def view_assigns
      {
        report: report,
        filter: filter,
        title: Translation.translate('HMIS Data Quality Tool'),
        pdf: true,
        # Ensure we have per-page JS
        per_page_js: [
          'hmis_dq_tool_chart',
          'hmis_dq_tool_completeness',
          'hmis_dq_tool_time_to_enter',
          'hmis_dq_tool_time_in_enrollment',
        ],
      }
    end

    def perform
      with_status_progression do
        template_file = 'hmis_data_quality_tool/warehouse_reports/reports/by_chart_pdf'
        layout = 'layouts/performance_report'
        # https://stackoverflow.com/questions/55865582/set-dynamic-header-and-footer-data-on-pdf-generation-from-rails-grover-gem

        html = PdfGenerator.html(
          controller: controller_class,
          template: template_file,
          layout: layout,
          user: user,
          assigns: view_assigns,
        )
        PdfGenerator.new.perform(
          html: html,
          file_name: "#{Translation.translate('HMIS Data Quality Tool')} #{DateTime.current.to_fs(:db)}",
          options: {
            print_background: true,
            display_header_footer: true,
            header_template: '',
            footer_template: ApplicationController.render(template: 'hmis_data_quality_tool/warehouse_reports/reports/pdf_footer', layout: false),
            wait_until: 'networkidle0',
            margin: {
              bottom: '.75in',
            },
          },
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    protected def report_class
      HmisDataQualityTool::Report
    end

    private def controller_class
      HmisDataQualityTool::WarehouseReports::ReportsController
    end
  end
end
