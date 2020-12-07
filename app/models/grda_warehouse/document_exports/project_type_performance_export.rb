###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::DocumentExports
  class ProjectTypePerformanceExport < BasePerformanceExport
    def perform
      with_status_progression do
        template_file = 'performance_dashboards/project_type/index_pdf'
        PdfGenerator.new.perform(
          html: view.render(file: template_file, layout: 'layouts/performance_report'),
          file_name: "ProjectType Performance #{DateTime.current.to_s(:db)}",
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    def download_title
      'Project Type Performance Report'
    end

    protected def report_class
      PerformanceDashboards::ProjectType
    end

    protected def view
      context = PerformanceDashboards::ProjectTypeController.view_paths
      view = ProjectTypePerformanceExportTemplate.new(context, view_assigns)
      view.current_user = user
      view
    end

    class ProjectTypePerformanceExportTemplate < PdfExportTemplateBase
      def show_client_details?
        @show_client_details ||= current_user.can_view_clients?
      end

      def details_performance_dashboards_project_type_index_path(*args) # rubocop:disable Lint/UnusedMethodArgument
        '#'
      end
    end
  end
end
