###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class HmisSimulation::RunLog < GrdaWarehouseBase
  self.table_name = 'hmis_simulation_run_logs'

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  scope :successful, -> { where(error_message: nil) }

  def self.last_successful_run_date(data_source_id)
    where(data_source_id: data_source_id).successful.maximum(:run_date)
  end
end
