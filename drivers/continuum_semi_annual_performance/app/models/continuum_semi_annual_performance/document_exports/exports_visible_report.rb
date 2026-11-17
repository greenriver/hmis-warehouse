###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ContinuumSemiAnnualPerformance::DocumentExports
  module ExportsVisibleReport
    ALL_TABS = 'all'

    def authorized?
      user.can_view_any_reports? &&
        report.present? &&
        report.completed? &&
        !report.purged? &&
        report.class.definition_viewable_by?(user) &&
        valid_tab?
    end

    def params
      @params ||= Rack::Utils.parse_nested_query(query_string).with_indifferent_access
    end

    protected def report
      @report ||= ContinuumSemiAnnualPerformance::Report.viewable_by(user).find_by(id: params['id'].to_s)
    end

    private def tab
      params['tab'].to_s.presence || ALL_TABS
    end

    private def valid_tab?
      tab == ALL_TABS || report.tabs.map(&:to_s).include?(tab)
    end

    private def selected_tabs
      tab == ALL_TABS ? report.tabs : [tab.to_sym]
    end
  end
end
