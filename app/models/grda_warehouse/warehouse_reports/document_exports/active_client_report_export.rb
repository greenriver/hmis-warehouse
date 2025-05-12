###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::WarehouseReports::DocumentExports
  class ActiveClientReportExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    def authorized?
      user.can_view_any_reports? && report_class.viewable_by(user)
    end

    protected def report
      @report ||= report_class.new(filter: filter, user: user)
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
        pdf = []
        template_file = 'warehouse_reports/client_details/actives/index_pdf'
        layout = 'layouts/open_path_logo_report'

        # Render the first page of the report
        html = PdfGenerator.html(
          controller: controller_class,
          template: template_file,
          layout: layout,
          user: user,
          assigns: view_assigns,
        )
        pdf << PdfGenerator.merge_inline_pdfs(PdfGenerator.render_pdf(html))

        # Split up the report table into batches to prevent issues when rendering extremely large tables in a single PDF
        @report.enrollment_scope.preload(:client, :project, :enrollment).in_batches(of: 5_000).each do |batch|
          html = PdfGenerator.html(
            controller: controller_class,
            layout: layout,
            template: 'warehouse_reports/client_details/actives/_pdf_table',
            user: user,
            assigns: view_assigns.deep_merge({
                                               batch: batch,
                                             }),
          )
          pdf << PdfGenerator.merge_inline_pdfs(PdfGenerator.render_pdf(html))
        end

        # Merge all the generated pdf files into a single PDF
        PdfGenerator.new.perform(
          html: '',
          file_name: "Active Clients #{DateTime.current.to_fs(:db)}",
          pdf_data: PdfGenerator.merge_inline_pdfs(pdf),
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    protected def report_class
      ActiveClientReport
    end

    private def controller_class
      ::WarehouseReports::ClientDetails::ActivesController
    end
  end
end
