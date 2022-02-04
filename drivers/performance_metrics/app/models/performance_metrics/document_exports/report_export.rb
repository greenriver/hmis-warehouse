###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMetrics::DocumentExports
  class ReportExport < ::GrdaWarehouse::DocumentExport
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
        pdf: true,
      }
    end

    def perform
      with_status_progression do
        template_file = 'performance_metrics/warehouse_reports/report/index_pdf'
        layout = 'layouts/performance_report'

        html = PdfGenerator.html(
          controller: controller_class,
          template: template_file,
          layout: layout,
          user: user,
          assigns: view_assigns,
        )
        PdfGenerator.new.perform(
          html: html,
          file_name: "#{_('Performance Metrics')} #{DateTime.current.to_s(:db)}",
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    protected def report_class
      PerformanceMetrics::Report
    end

    private def controller_class
      PerformanceMetrics::WarehouseReports::ReportsController
    end
  end
end
