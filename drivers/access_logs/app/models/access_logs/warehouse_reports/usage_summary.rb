###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AccessLogs::WarehouseReports::UsageSummary
  include ArelHelper

  def initialize(range:)
    @range = range
  end

  def call
    Rails.cache.fetch(cache_key, expires_in: 15.minutes) { build }
  end

  private

  def build
    rows = grouped_rows
    reports = report_names.filter_map { |url, name| build_report(url, name, rows) }
    user_totals = Hash.new(0)
    rows.each { |_report_key, user_id, visit_days| user_totals[user_id.to_s] += visit_days }
    { reports: reports, user_totals: user_totals, date_range: { start: @range.begin, end: @range.end } }
  end

  def build_report(url, name, rows)
    user_visits = rows.select { |report_key, _, _| report_key == url }.
      to_h { |_, user_id, visit_days| [user_id.to_s, visit_days] }
    return if user_visits.empty?

    { key: url, name: name, unique_visits: user_visits.values.sum, unique_users: user_visits.size, user_visits: user_visits }
  end

  # One grouped query: report_key (via CASE, first-match-wins) x user_id x COUNT(DISTINCT day).
  # Reuses ActivityLog.warehouse_reports for the WHERE so "what counts as a report url" has one source of truth.
  def grouped_rows
    at = ActivityLog.arel_table
    report_key = acase(report_names.keys.map { |url| [at[:path].matches("/#{url}%"), url] })
    visit_day = cast(at[:created_at], 'date')

    ActivityLog.warehouse_reports.created_in_range(range: @range).
      group(report_key, :user_id).
      pluck(report_key, :user_id, Arel::Nodes::Count.new([visit_day], true))
  end

  def report_names
    @report_names ||= GrdaWarehouse::WarehouseReports::ReportDefinition.report_list.values.flatten.
      each_with_object({}) { |r, h| h[r[:url]] = r[:name] }
  end

  def cache_key
    ['access_logs/usage_summary', @range.begin, @range.end]
  end
end
