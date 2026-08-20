###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ActivityLog < ApplicationRecord
  include ArelHelper

  belongs_to :user

  scope :created_in_range, ->(range:) do
    where(created_at: range)
  end

  scope :warehouse_reports, -> do
    where(warehouse_report_conditions.map(&:last).reduce(:or))
  end

  # [url, arel condition] per ReportDefinition.report_list entry. Each report's condition
  # defaults to a path-prefix match, but can be overridden via a `reporting_query` lambda on the
  # report_list entry (see the Nightly Census entry in report_definition.rb, whose date_range/
  # details sub-routes are also hit by a widget embedded on other pages, so a bare path match
  # would over-count). Shared by the `warehouse_reports` scope above and by
  # AccessLogs::WarehouseReports::UsageSummary, which needs the same per-report conditions
  # individually (not just OR'd together) to attribute each row to a report.
  def self.warehouse_report_conditions
    GrdaWarehouse::WarehouseReports::ReportDefinition.report_list.values.flatten.map do |r|
      [r[:url], r[:reporting_query]&.call(arel_table) || arel_table[:path].matches("/#{r[:url]}%")]
    end
  end

  def clean_object_name
    item_model&.gsub('GrdaWarehouse::Hud::', '')
  end

  # increment can be: minute, hour, day, week, month, year
  def self.for_chart(increment: 'hour', range: 1.weeks.ago..Time.current)
    return [] unless valid_increments.include?(increment)

    data = {}
    where(created_at: range).
      group(:created_at_trunc, :user_id).
      pluck(Arel.sql("date_trunc('#{increment}', created_at) as created_at_trunc"), :user_id).
      each do |time, _user_id|
        data[time.strftime('%Y-%m-%d %H:%M')] ||= 0
        data[time.strftime('%Y-%m-%d %H:%M')] += 1
      end
    [
      ['x'] + data.keys,
      ['Active Users'] + data.values,
    ]
  end

  def self.valid_increments
    ['minute', 'hour', 'day', 'week', 'month', 'year']
  end

  def self.to_a(user_id: nil, range: 1.years.ago..Time.current)
    columns = {
      user_id: 'User ID',
      agency_name_column => 'Agency Name',
      path: 'Path',
      created_at: 'Access Time',
      session_hash: 'Session',
      ip_address: 'IP Address',
      referrer: 'Referrer',
    }
    scope = where(created_at: range).left_outer_joins(user: :agency)
    scope = scope.where(user_id: user_id) if user_id.present?
    rows = [columns.values]
    scope.in_batches do |batch|
      data = pluck_to_hash(columns, batch)
      data = scrub(data)
      data.each do |row|
        rows << row.values
      end
    end
    rows
  end

  def self.agency_name_column
    Agency.arel_table[:name]
  end

  def self.scrub(data)
    report_replacements = GrdaWarehouse::WarehouseReports::ReportDefinition.pluck(:id, :name)
    data.map do |row|
      # Strip anything after the ?
      row[:path] = row[:path]&.gsub(/\?.*/, '')
      row[:referrer] = row[:referrer]&.gsub(/\?.*/, '')
      row[:created_at] = row[:created_at].to_fs(:db)
      cleanup_report_paths(row, report_replacements)
    end
  end

  def self.pluck_to_hash(columns, scope)
    scope.pluck(*columns.keys).map do |row|
      Hash[columns.keys.zip(row)]
    end
  end

  def self.cleanup_report_paths(row, report_replacements)
    return row unless row[:path].starts_with?('/reports/')

    report_replacements.each do |id, name|
      row[:path] = row[:path].sub("/reports/#{id}/", "/reports/#{name.parameterize}/")
    end
    row
  end
end
