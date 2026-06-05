###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class HmisSimulation::LifecycleEnrollment < GrdaWarehouseBase
  self.table_name = 'hmis_simulation_lifecycle_enrollments'

  STATUSES = ['pending_open', 'open', 'closed'].freeze

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  scope :pending_open_on, ->(date) { where(status: 'pending_open', opens_on: date) }
  scope :open_for_client, ->(client_id) { where(hud_client_id: client_id, status: 'open') }
end
