###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class BackgroundRender::AccessLogsReportUsageJob < BackgroundRenderJob
  def render_html(filters:, user_id:)
    filter = ::Filters::FilterBase.new(user_id: user_id).set_from_params(JSON.parse(filters).with_indifferent_access)
    summary = AccessLogs::WarehouseReports::UsageSummary.new(range: filter.start..filter.end).call
    users = User.where(id: summary[:user_totals].keys).index_by { |u| u.id.to_s }

    AccessLogs::WarehouseReports::ReportsController.render(
      partial: 'access_logs/warehouse_reports/reports/report_usage_content',
      assigns: { summary: summary, users: users },
    )
  end
end
