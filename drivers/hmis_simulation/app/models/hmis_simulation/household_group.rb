###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class HmisSimulation::HouseholdGroup < GrdaWarehouseBase
  self.table_name = 'hmis_simulation_household_groups'

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  has_many :simulated_clients, class_name: 'HmisSimulation::Client', foreign_key: :household_group_id
end
