###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::DocumentExports
  class ClientPerformanceExport < BasePerformanceExport
    def perform
      with_status_progression do
        template_file = 'performance_dashboards/overview/index_pdf'
        PdfGenerator.new.perform(
          html: view.render(file: template_file, layout: 'layouts/performance_report'),
          file_name: "Client Performance #{DateTime.current.to_s(:db)}",
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    def download_title
      'Client Performance Report'
    end

    protected def report_class
      PerformanceDashboards::Overview
    end

    protected def view
      context = PerformanceDashboards::OverviewController.view_paths
      view = ClientPerformanceExportTemplate.new(context, view_assigns)
      view.current_user = user
      view
    end

    class ClientPerformanceExportTemplate < ActionView::Base
      include ActionDispatch::Routing::PolymorphicRoutes
      include Rails.application.routes.url_helpers
      include ApplicationHelper
      attr_accessor :current_user
      def show_client_details?
        @show_client_details ||= current_user.can_view_clients?
      end

      def details_performance_dashboards_overview_index_path(*args)
        '#'
      end

      def breakdown # rubocop:disable Style/TrivialAccessors
        @breakdown
      end
    end
  end
end
