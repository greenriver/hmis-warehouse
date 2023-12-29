###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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
end
