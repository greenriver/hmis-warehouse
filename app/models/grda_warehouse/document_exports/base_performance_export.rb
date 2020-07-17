###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
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
      if report.include_comparison?
        comparison_report = report_class.new(comparison_filter)
      end

      {
        report: report,
        filter: filter,
        comparison: comparison_report || report,
        comparison_filter: comparison_filter,
        breakdown: breakdown,
        pdf: true,
        report_variant: 'sparse',
      }
    end

    protected def breakdown
      params['breakdown']&.to_sym || report.available_breakdowns.keys.first
    end

    protected def filter
      @filter ||= begin
        f = ::Filters::PerformanceDashboard.new(user_id: user.id)
        filter_params = params['filters'].presence&.deep_symbolize_keys
        if filter_params
          f.set_from_params(filter_params)
        end
        f
      end
    end

    protected def params
      query_string.present? ? Rack::Utils.parse_nested_query(query_string) : {}
    end
  end
end
