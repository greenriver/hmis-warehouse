###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddNextPopulationToHmisSimulationClients < ActiveRecord::Migration[7.2]
  def change
    # Omit `algorithm: :concurrently`, so the migration runs in one transaction.
    # This avoids needing disable_ddl_transaction! which we've had issues with in the past.
    # The table is new and small, so a brief build lock is acceptable.
    safety_assured do
      add_column :hmis_simulation_clients, :next_population, :string unless column_exists?(:hmis_simulation_clients, :next_population)
      add_index :hmis_simulation_clients, [:data_source_id, :next_population], if_not_exists: true
    end
  end
end
