###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class RemoveRedundantHmisSimulationDataSourceIdIndexes < ActiveRecord::Migration[7.2]
  def change
    remove_index :hmis_simulation_clients, name: 'index_hmis_simulation_clients_on_data_source_id', if_exists: true

    remove_index :hmis_simulation_concurrent_enrollments, name: 'index_hmis_simulation_concurrent_enrollments_on_data_source_id', if_exists: true

    remove_index :hmis_simulation_lifecycle_enrollments, name: 'index_hmis_simulation_lifecycle_enrollments_on_data_source_id', if_exists: true

    remove_index :hmis_simulation_run_logs, name: 'index_hmis_simulation_run_logs_on_data_source_id', if_exists: true
  end
end
