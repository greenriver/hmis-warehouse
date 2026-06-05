###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class HmisSimulation::Client < GrdaWarehouseBase
  self.table_name = 'hmis_simulation_clients'

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :household_group, class_name: 'HmisSimulation::HouseholdGroup', optional: true

  scope :active, -> { where(exited_system: false) }
  scope :pending_enrollment, ->(date) { where(pending_enrollment_on: date) }
  scope :pending_exit, ->(date) { where(next_transition_on: date) }
end
