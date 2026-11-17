###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ContinuumSemiAnnualPerformance
  module ReportsHelper
    SUMMARY_TAB_TITLE = 'Summary'

    DRILLDOWN_REPORTS = { 'apr' => :aprs, 'ce_apr' => :ce_aprs }.freeze

    def drilldown_path(part)
      args = { question_id: "Question #{part['table'][/\d+/]}", id: part['cell'], table: part['table'] }
      case part['report']
      when 'apr' then hud_reports_apr_question_cell_path(apr_id: part['hud_report_id'], **args)
      when 'ce_apr' then hud_reports_ce_apr_question_cell_path(ce_apr_id: part['hud_report_id'], **args)
      end
    end

    # Keep in step with the HUD cell page's access checks, so a link appears only when that page would open.
    def drilldown_visible?(report, part)
      access = drilldown_access(report)
      access[:definitions][part['report']] && access[:openable_ids].include?(part['hud_report_id'])
    end

    def self.tab_title(tab)
      tab = tab.to_sym
      return SUMMARY_TAB_TITLE if tab == :summary

      HudHelper.util.project_type_group_titles.fetch(ContinuumSemiAnnualPerformance::Report::PERFORMANCE_KEYS.fetch(tab, tab))
    end

    def tab_title(tab)
      ReportsHelper.tab_title(tab)
    end

    def report_action_path(report, action, **params)
      url_for(controller: "/#{report.class.url}", action: action, id: report.id, only_path: true, **params)
    end

    private def drilldown_access(report)
      @drilldown_access ||= {}
      @drilldown_access[report.id] ||= begin
        can_open = current_user.can_view_any_reports?
        definitions = DRILLDOWN_REPORTS.transform_values do |key|
          can_open && GrdaWarehouse::WarehouseReports::ReportDefinition.url_viewable_by?(GrdaWarehouse::WarehouseReports::ReportDefinition.hud_url(key), current_user)
        end
        { definitions: definitions, openable_ids: can_open ? openable_hud_report_ids(report) : [] }
      end
    end

    private def openable_hud_report_ids(report)
      HudReports::ReportInstance.viewable_by(current_user).
        where(id: report.hud_report_ids.values.compact).
        select(:id, :archival_metadata).to_a.
        reject(&:purged?).map(&:id)
    end
  end
end
