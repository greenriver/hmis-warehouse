###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::DocumentExports
  class ProjectTypePerformanceExport < BasePerformanceExport
    def perform
      with_status_progression do
        template_file = 'performance_dashboards/project_type/index_pdf'
        layout = 'layouts/performance_report'

        html = PdfGenerator.html(
          controller: controller_class,
          template: template_file,
          layout: layout,
          user: user,
          assigns: view_assigns,
        )
        PdfGenerator.new.perform(
          html: html,
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

    private def controller_class
      PerformanceDashboards::ProjectTypeController
    end

    class ProjectTypePerformanceExportTemplate < PdfExportTemplateBase
      def show_client_details?
        @show_client_details ||= current_user.can_access_some_version_of_clients?
      end

      def details_performance_dashboards_project_type_index_path(*args) # rubocop:disable Lint/UnusedMethodArgument
        '#'
      end
    end
  end
end
