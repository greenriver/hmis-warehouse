###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# = Hmis::ActivityLog
#
# Tracks GraphQL API access. See related tables:
#   * hmis_activity_logs_clients
#   * hmis_activity_logs_enrollments
#   * hmis_activity_logs_projects
class Hmis::ActivityLog < ApplicationRecord
  self.table_name = :hmis_activity_logs
  belongs_to :user, class_name: 'Hmis::User'
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  scope :unprocessed, -> { where(processed_at: nil) }
end
