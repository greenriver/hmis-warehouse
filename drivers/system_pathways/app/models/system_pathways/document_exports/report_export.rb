###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module SystemPathways::DocumentExports
  class ReportExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    def authorized?
      user.can_view_any_reports? &&
        GrdaWarehouse::WarehouseReports::ReportDefinition.url_viewable_by?(report_class.url, user) &&
        report.present?
    end

    protected def report
      @report ||= report_class.visible_to(user).find_by(id: params['id'])
    end

    protected def view_assigns
      {
        report: report,
        filter: filter,
        title: Translation.translate('System Pathways'),
        pdf: true,
      }
    end

    def perform
      with_status_progression do
        template_file = 'system_pathways/warehouse_reports/reports/show_pdf'
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
          file_name: "#{Translation.translate('System Pathways')} #{DateTime.current.to_fs(:db)}",
          options: {
            print_background: true,
            display_header_footer: false,
            header_template: '',
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
      SystemPathways::Report
    end

    private def controller_class
      SystemPathways::WarehouseReports::ReportsController
    end
  end
end
