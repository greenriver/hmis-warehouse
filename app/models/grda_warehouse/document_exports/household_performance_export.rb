###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::DocumentExports
  class HouseholdPerformanceExport < BasePerformanceExport
    def perform
      with_status_progression do
        template_file = 'performance_dashboards/overview/index_pdf'
        PdfGenerator.new.perform(
          html: view.render(file: template_file, layout: 'layouts/performance_report'),
          file_name: "Household Performance #{DateTime.current.to_s(:db)}",
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    def download_title
      'Household Performance Report'
    end

    protected def report_class
      PerformanceDashboards::Household
    end

    protected def view
      context = PerformanceDashboards::HouseholdController.view_paths
      view = HouseholdPerformanceExportTemplate.new(context, view_assigns)
      view.current_user = user
      view
    end

    class HouseholdPerformanceExportTemplate < PdfExportTemplateBase
      def show_client_details?
        @show_client_details ||= current_user.can_access_some_version_of_clients?
      end

      def details_performance_dashboards_household_index_path(*args)
        '#'
      end

      def breakdown # rubocop:disable Style/TrivialAccessors
        @breakdown
      end
    end
  end
end
