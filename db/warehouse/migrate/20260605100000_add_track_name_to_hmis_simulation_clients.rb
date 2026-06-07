###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddTrackNameToHmisSimulationClients < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_column :hmis_simulation_clients, :track_name, :string
    add_index :hmis_simulation_clients, [:data_source_id, :track_name], algorithm: :concurrently
  end
end
