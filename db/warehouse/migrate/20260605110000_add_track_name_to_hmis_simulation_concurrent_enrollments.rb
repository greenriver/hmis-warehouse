# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class AddTrackNameToHmisSimulationConcurrentEnrollments < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_column :hmis_simulation_concurrent_enrollments, :track_name, :string
    add_index :hmis_simulation_concurrent_enrollments, [:data_source_id, :track_name], algorithm: :concurrently
  end
end
