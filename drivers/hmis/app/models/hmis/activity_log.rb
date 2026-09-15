###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# = Hmis::ActivityLog
#
# Tracks HMIS request activity for auditing and downstream access summaries.
#
# Purpose
# - Records GraphQL API requests and other HMIS accesses (e.g., client file redirects)
# - `Hmis::ActivityLogProcessorJob` later resolves entity references and populates
#   join tables to support client/enrollment access summaries.
#
# Lifecycle
# - Inserted at request time with metadata and `resolved_fields`
# - Processor job batches records with `processed_at: nil`, resolves references, and
#   populates join tables:
#   * `hmis_activity_logs_clients(activity_log_id, client_id)`
#   * `hmis_activity_logs_enrollments(activity_log_id, enrollment_id, project_id)`
# - Marks records as processed by setting `processed_at`
#
# Key fields
# - user_id: HMIS user who initiated the request (required)
# - data_source_id: HMIS data source context (required)
# - ip_address: string IP of requester (required)
# - session_hash: string session id; maps to session_id in other tables
# - request_id: string request UUID; correlates to X-Request-Id/Sentry
# - operation_name: free-form operation label (e.g., GraphQL op name)
# - variables (jsonb): arbitrary request metadata for correlation (e.g., {"fileId": 42})
# - referer: user-provided referer
# - header_page_path/header_client_id/header_enrollment_id/header_project_id: user-provided headers
# - created_at: timestamp request was logged
# - resolved_fields (jsonb): map of root objects to accessed fields. Keys must be
#   strings in the format:
#     "Client/<id>", "Enrollment/<id>", "EnrollmentSummary/<id>", "Assessment/<id>"
#   Values are arrays of field names and are optional for processing; the processor
#   only uses the keys to resolve entity IDs.
# - resolved_at: timestamp of the last captured event (when applicable)
# - processed_at: set by the processor job once join rows are created
#
# Example
#   {
#     user_id: 123,
#     data_source_id: 1,
#     operation_name: 'ClientFileRedirect',
#     variables: { 'fileId' => 42, 'clientId' => 7 },
#     resolved_fields: { 'Client/7' => ['files'] },
#     resolved_at: Time.current,
#   }
class Hmis::ActivityLog < ApplicationRecord
  self.table_name = :hmis_activity_logs
  belongs_to :user, class_name: 'Hmis::User'
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  scope :unprocessed, -> { where(processed_at: nil) }

  # `range` is a Date..Date; created_at is a UTC instant, so bare Date bounds would drop
  # evening (Eastern) activity on the last day.
  scope :created_in_range, ->(range:) do
    where(created_at: range.begin.beginning_of_day..range.end.end_of_day)
  end

  USER_SUMMARY_INDEX_NAME = 'index_hmis_activity_logs_on_created_at_and_user_id'

  # Same shape as ActivityLog.export_rows. data_source lives in the warehouse database, so its
  # name is mapped in Ruby rather than joined.
  def self.export_rows(user_id: nil, range: 1.years.ago..Time.current, limit: nil)
    columns = {
      user_id: 'HMIS User ID',
      data_source_id: 'Data Source',
      operation_name: 'Operation',
      header_page_path: 'Page',
      created_at: 'Access Time',
      session_hash: 'Session',
      ip_address: 'IP Address',
      referer: 'Referrer',
    }
    scope = where(created_at: range)
    scope = scope.where(user_id: user_id) if user_id.present?
    scope = scope.limit(limit) if limit

    Enumerator.new do |rows|
      rows << columns.values
      data_source_names = GrdaWarehouse::DataSource.hmis.pluck(:id, :name).to_h
      scope.in_batches do |batch|
        batch.pluck(*columns.keys).each do |values|
          row = columns.keys.zip(values).to_h
          row[:data_source_id] = data_source_names[row[:data_source_id]]
          row[:header_page_path] = row[:header_page_path]&.gsub(/\?.*/, '')
          row[:referer] = row[:referer]&.gsub(/\?.*/, '')
          row[:created_at] = row[:created_at].to_fs(:db)
          rows << row.values
        end
      end
    end
  end

  # Build an index by a TaskQueue task rather than a migration because this table gets heavy use and we want to build concurrently.
  # This is an idempotent build:
  # If the index exists and is valid, do nothing
  # If the index is invalid, drop it and rebuild it
  # If the index does not exist, create it
  def self.ensure_user_summary_index!
    valid = connection.select_value(<<~SQL)
      SELECT i.indisvalid FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid WHERE c.relname = #{connection.quote(USER_SUMMARY_INDEX_NAME)}
    SQL
    return if valid == true

    connection.remove_index(table_name, name: USER_SUMMARY_INDEX_NAME, algorithm: :concurrently) if valid == false
    connection.add_index(table_name, [:created_at, :user_id], name: USER_SUMMARY_INDEX_NAME, algorithm: :concurrently)
  end

  # Logically HmisActivityLog is HABTM to clients and enrollments. However due to the database boundary, we do not
  # define active record associations for those; the joins from such associations would be invalid sql.
  #
  # The id accessor methods below are used to compose sub-queries to filter the enrollment/client "summary" db views
  # that are exposed in the API
  def self.select_client_ids
    jt = Arel::Table.new(:hmis_activity_logs_clients)
    join_clause = arel_table.create_join(jt, arel_table.create_on(jt[:activity_log_id].eq(arel_table[:id])))
    joins(join_clause).select(jt[:client_id])
  end

  def self.select_enrollment_ids
    jt = Arel::Table.new(:hmis_activity_logs_enrollments)
    join_clause = arel_table.create_join(jt, arel_table.create_on(jt[:activity_log_id].eq(arel_table[:id])))
    joins(join_clause).select(jt[:enrollment_id])
  end

  def response_time
    resolved_at - created_at if resolved_at
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
end
