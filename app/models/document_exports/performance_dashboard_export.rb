###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module DocumentExports
  class PerformanceDashboardExport < DocumentExport
    def authorized?
      if Rails.env.development?
        # FIXME - is this right?
        user.can_view_censuses? && user.can_view_clients?
      else
        raise 'auth not implemented'
      end
    end

    def perform
      with_status_progression do
        context = PerformanceDashboards::OverviewController.view_paths
        view = PerformanceDashboardExportTemplate.new(context, view_assigns)
        view.current_user = user
        render_to_pdf!(
          view: view,
          file: 'performance_dashboards/overview/index_pdf'
        )
      end
    end

    protected

    def view_assigns
      # FIXME: - tbd
      filter_set = param_filter_set
      {
        report: PerformanceDashboards::Overview.new(filter_set),
        filter: filter_set,
        comparison: filter_set.to_comparison_set,
        breakdown: breakdown,
        pdf: true,
      }
    end

    def breakdown
      params['breakdown']&.to_sym || :age
    end

    def param_filter_set
      filter = PerformanceDashboards::ReportFilterSet.new
      filter.user = user
      filter.assign_attributes(params['filters'])
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
