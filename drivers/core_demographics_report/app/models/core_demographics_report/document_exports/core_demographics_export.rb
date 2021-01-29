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
        template_file = 'core_demographics_report/warehouse_reports/core/index_pdf'
        PdfGenerator.new.perform(
          html: view.render(file: template_file, layout: 'layouts/performance_report'),
          file_name: "Core Demographics #{DateTime.current.to_s(:db)}",
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    protected def report_class
      CoreDemographicsReport::Core
    end

    protected def view
      context = CoreDemographicsReport::WarehouseReports::CoreController.view_paths
      view = CoreDemographicsExportTemplate.new(context, view_assigns)
      view.current_user = user
      view
    end

    class CoreDemographicsExportTemplate < PdfExportTemplateBase
      def show_client_details?
        @show_client_details ||= current_user.can_view_clients?
      end

      # def details_performance_dashboards_overview_index_path(*args)
      #   '#'
      # end
    end
  end
end
