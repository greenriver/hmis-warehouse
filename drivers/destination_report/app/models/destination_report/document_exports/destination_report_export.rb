###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module DestinationReport::DocumentExports
  class DestinationReportExport < ::GrdaWarehouse::DocumentExport
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
        template_file = 'destination_report/warehouse_reports/destination_report/index_pdf'
        PdfGenerator.new.perform(
          html: view.render(file: template_file, layout: 'layouts/performance_report'),
          file_name: "Destination #{DateTime.current.to_s(:db)}",
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    protected def report_class
      DestinationReport::DestinationReportReport
    end

    protected def view
      context = DestinationReport::WarehouseReports::DestinationReportController.view_paths
      view = DestinationReportExportTemplate.new(context, view_assigns)
      view.current_user = user
      view
    end

    class DestinationReportExportTemplate < PdfExportTemplateBase
      def show_client_details?
        @show_client_details ||= current_user.can_view_clients?
      end
    end
  end
end
