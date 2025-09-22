# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
