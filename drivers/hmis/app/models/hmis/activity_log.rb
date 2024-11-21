###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# = Hmis::ActivityLog
#
# Tracks GraphQL API access
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
