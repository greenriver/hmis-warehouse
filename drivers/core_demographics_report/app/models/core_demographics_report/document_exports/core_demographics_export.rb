###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CoreDemographicsReport::DocumentExports
  class CoreDemographicsExport < ::GrdaWarehouse::DocumentExport
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
        template_file = File.join(Rails.root, 'drivers/core_demographics_report/app/views/core_demographics_report/warehouse_reports/core/index_pdf.haml')
        layout = 'layouts/performance_report.html'

        html = controller_class.render(
          file: template_file,
          layout: layout,
          assigns: view_assigns,
        )
        PdfGenerator.new.perform(
          html: html,
          file_name: "Core Demographics #{DateTime.current.to_s(:db)}",
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    protected def report_class
      CoreDemographicsReport::Core
    end

    private def controller_class
      CoreDemographicsReport::WarehouseReports::CoreController
    end

    private def view_context
      controller_class.view_paths
    end

    protected def view
      view = CoreDemographicsExportTemplate.new(view_context, view_assigns, controller_class.new)
      view.current_user = user
      view
    end

    class CoreDemographicsExportTemplate < PdfExportTemplateBase
      def show_client_details?
        @show_client_details ||= current_user.can_access_some_version_of_clients?
      end

      # def details_performance_dashboards_overview_index_path(*args)
      #   '#'
      # end
    end
  end
end
