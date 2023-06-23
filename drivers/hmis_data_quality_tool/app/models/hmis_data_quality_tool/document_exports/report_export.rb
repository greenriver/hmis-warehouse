###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisDataQualityTool::DocumentExports
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
        title: _('HMIS Data Quality Tool'),
        pdf: true,
      }
    end

    def perform
      with_status_progression do
        template_file = 'hmis_data_quality_tool/warehouse_reports/reports/show_pdf'
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
          file_name: "#{_('HMIS Data Quality Tool')} #{DateTime.current.to_s(:db)}",
          options: {
            print_background: true,
            display_header_footer: true,
            header_template: '',
            footer_template: ApplicationController.render(template: 'hmis_data_quality_tool/warehouse_reports/reports/pdf_footer', layout: false),
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
