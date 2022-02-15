###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::DocumentExports
  class BasePerformanceExport < ::GrdaWarehouse::DocumentExport
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
        breakdown: breakdown,
        pdf: true,
      }
    end

    protected def breakdown
      params['breakdown']&.to_sym || report.available_breakdowns.keys.first
    end

    protected def filter
      @filter ||= begin
        f = ::Filters::PerformanceDashboard.new(user_id: user.id)
        filter_params = params['filters'].presence&.deep_symbolize_keys
        f.set_from_params(filter_params) if filter_params
        f
      end
    end

    protected def params
      query_string.present? ? Rack::Utils.parse_nested_query(query_string) : {}
    end
  end
end
