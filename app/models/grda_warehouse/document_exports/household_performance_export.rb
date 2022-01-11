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
        layout = 'layouts/performance_report'

        ActionController::Renderer::RACK_KEY_TRANSLATION['warden'] ||= 'warden'
        renderer = controller_class.renderer.new(
          'warden' => PdfGenerator.warden_proxy(user),
        )
        html = renderer.render(
          template_file,
          layout: layout,
          assigns: view_assigns,
        )
        PdfGenerator.new.perform(
          html: html,
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

    private def controller_class
      PerformanceDashboards::HouseholdController
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
