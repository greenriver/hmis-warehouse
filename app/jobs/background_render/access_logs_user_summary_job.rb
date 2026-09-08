###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class BackgroundRender::AccessLogsUserSummaryJob < BackgroundRenderJob
  def render_html(filters:, user_id:)
    filter = ::Filters::FilterBase.new(user_id: user_id).set_from_params(JSON.parse(filters).with_indifferent_access)
    summary = AccessLogs::WarehouseReports::UserSummary.new(range: filter.start..filter.end).call
    user_ids = summary[:access].values.flatten.map { |row| row[:user_id] } + summary[:created][:all].map { |row| row[:user_id] }
    users = User.where(id: user_ids.uniq).index_by(&:id)

    AccessLogs::WarehouseReports::ReportsController.render(
      partial: 'access_logs/warehouse_reports/reports/user_summary_content',
      assigns: { summary: summary, users: users },
    )
  end
end
