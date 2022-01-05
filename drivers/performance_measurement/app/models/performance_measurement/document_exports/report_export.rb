###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMeasurement::DocumentExports
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
        template_file = 'performance_measurement/warehouse_reports/reports/show_pdf'
        # https://stackoverflow.com/questions/55865582/set-dynamic-header-and-footer-data-on-pdf-generation-from-rails-grover-gem
        PdfGenerator.new.perform(
          html: view.render(file: template_file, layout: 'layouts/performance_report'),
          file_name: "#{_('Performance Management Dashboard')} #{DateTime.current.to_s(:db)}",
          options: {
            print_background: true,
            display_header_footer: true,
            header_template: '',
            footer_template: ApplicationController.render(template: 'performance_measurement/warehouse_reports/reports/pdf_footer', layout: false),
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
      PerformanceMeasurement::Report
    end

    protected def view
      context = PerformanceMeasurement::WarehouseReports::ReportsController.view_paths
      view = ReportExportTemplate.new(context, view_assigns)
      view.current_user = user
      view
    end

    class ReportExportTemplate < PdfExportTemplateBase
      def show_client_details?
        @show_client_details ||= current_user.can_access_some_version_of_clients?
      end
    end
  end
end
