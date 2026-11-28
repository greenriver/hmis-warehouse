###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ContinuumSemiAnnualPerformance::DocumentExports
  class ReportPdfExport < ::GrdaWarehouse::DocumentExport
    include ExportsVisibleReport

    def perform
      with_status_progression do
        html = PdfGenerator.html(
          controller: report.class.controller_class,
          template: 'continuum_semi_annual_performance/warehouse_reports/reports/show_pdf',
          layout: 'layouts/performance_report',
          user: user,
          assigns: { report: report, tabs: selected_tabs, title: report.title },
        )
        PdfGenerator.new.perform(
          html: html,
          file_name: "#{report.title} - #{report.coc_code} #{DateTime.current.to_fs(:db)}",
        ) do |io|
          self.pdf_file = io
        end
      end
    end
  end
end
