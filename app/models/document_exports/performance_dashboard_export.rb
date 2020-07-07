###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module DocumentExports
  class PerformanceDashboardExport < DocumentExport
    def authorized?
      # FIXME - check this please
      user.can_view_censuses? && user.can_view_clients?
    end

    def perform
      with_status_progression do
        template_file = 'performance_dashboards/overview/index_pdf'
        PdfGenerator.new.perform(
          html: view.render(file: template_file),
          file_name: "Performance Overview #{DateTime.current.to_s(:db)}"
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    protected

    def view
      context = PerformanceDashboards::OverviewController.view_paths
      view = PerformanceDashboardExportTemplate.new(context, view_assigns)
      view.current_user = user
      view
    end

    def view_assigns
      filter = load_filter
      comparison_filter = filter.to_comparison
      report = PerformanceDashboards::Overview.new(filter)
      if report.include_comparison?
        comparison_report = PerformanceDashboards::Overview.new(comparison_filter)
      end

      {
        report: report,
        filter: filter,
        comparison: comparison_report || report,
        comparison_filter: comparison_filter,
        breakdown: breakdown,
        pdf: true,
      }
    end

    def breakdown
      params['breakdown']&.to_sym || :age
    end

    def load_filter
      filter = ::Filters::PerformanceDashboard.new(user_id: user.id)
      filter_params = params['filters'].presence&.symbolize_keys
      if filter_params
        filter.set_from_params(filter_params)
      end
      filter
    end

    def params
      query_string.present? ? Rack::Utils.parse_nested_query(query_string) : {}
    end

    class PerformanceDashboardExportTemplate < ActionView::Base
      include ApplicationHelper
      attr_accessor :current_user
      def show_client_details?
        @show_client_details ||= current_user.can_view_clients?
      end

      def details_performance_dashboards_overview_index_path(*args)
        '#'
      end
    end

  end
end
