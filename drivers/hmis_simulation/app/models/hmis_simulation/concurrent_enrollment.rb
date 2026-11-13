###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class HmisSimulation::ConcurrentEnrollment < GrdaWarehouseBase
  self.table_name = 'hmis_simulation_concurrent_enrollments'

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  validates :hud_client_id, :project_name, presence: true

  scope :expiring_on, ->(date) { where(exit_on: date) }
  scope :pending_reentry_on, ->(date) { where(pending_reentry_on: date) }
end
