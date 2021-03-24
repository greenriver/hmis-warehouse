###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module IncomeBenefitsReport::DocumentExports
  class IncomeBenefitsExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    def authorized?
      user.can_view_any_reports? && report_class.viewable_by(user)
    end

    protected def report
      @report ||= report_class.new(filter)
    end

    protected def view_assigns
      comparison_filter = filter.to_comparison
      comparison_report = report_class.new(comparison_filter) if report.include_comparison?

      {
        report: report,
        filter: filter,
        comparison: comparison_report || report,
        comparison_filter: comparison_filter,
        pdf: true,
      }
    end

    def perform
      with_status_progression do
        template_file = 'income_benefits_report/warehouse_reports/report/index_pdf'
        PdfGenerator.new.perform(
          html: view.render(file: template_file, layout: 'layouts/performance_report'),
          file_name: "Income Benefits #{DateTime.current.to_s(:db)}",
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    protected def report_class
      IncomeBenefitsReport::Core
    end

    protected def view
      context = IncomeBenefitsReport::WarehouseReports::CoreController.view_paths
      view = IncomeBenefitsExportTemplate.new(context, view_assigns)
      view.current_user = user
      view
    end

    class IncomeBenefitsExportTemplate < PdfExportTemplateBase
      def show_client_details?
        @show_client_details ||= current_user.can_access_some_version_of_clients?
      end
    end
  end
end
