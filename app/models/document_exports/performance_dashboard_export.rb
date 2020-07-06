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
        user.can_view_censuses? && can_view_clients?
      else
        raise 'auth not implemented'
      end
    end

    def perform
      with_status_progression do
        render_to_pdf!(
          context: PerformanceDashboards::OverviewController.view_paths,
          file: 'performance_dashboards/overview/index_pdf',
          assigns: view_assigns,
        )
      end
    end

    protected

    def view_assigns
      # FIXME: - tbd
      filter_set = param_filter_set
      {
        report: PerformanceDashboards::Overview.new(filter_set),
        comparison_dates: filter_set.to_comparison_set,
        breakdown: breakdown,
        pdf: true,
      }
    end

    def breakdown
      params[:breakdown]&.to_sym || :age
    end

    def param_filter_set
      filters = PerformanceDashboards::ReportFilterSet.new
      filter.current_user = user
      filter.assign_attributes(params[:filters])
      filters
    end

  end
end
