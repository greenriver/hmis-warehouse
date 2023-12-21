###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::ActivityLog < ApplicationRecord
  self.table_name = :hmis_activity_logs
  belongs_to :user, class_name: 'Hmis::User'

  # can't use rails association as we cross db boundaries
  def client_ids
    self.class.connection.select_values <<~SQL
      SELECT client_id FROM hmis_activity_logs_clients WHERE activity_log_id = #{self.class.connection.quote(id)}
    SQL
  end

  def enrollment_ids
    self.class.connection.select_values <<~SQL
      SELECT enrollment_id FROM hmis_activity_logs_enrollments WHERE activity_log_id = #{self.class.connection.quote(id)}
    SQL
  end

  def project_ids
    self.class.connection.select_values <<~SQL
      SELECT project_id FROM hmis_activity_logs_projects WHERE activity_log_id = #{self.class.connection.quote(id)}
    SQL
  end

  scope :unprocessed, -> { where(processed_at: nil) }
end
