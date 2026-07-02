###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class RenameHmisSimulationHouseholdGroupsMemberClientIds < ActiveRecord::Migration[7.2]
  def up
    # Omit `disable_ddl_transaction!`, so the migration runs in one transaction.
    # This avoids partial application when a rename succeeds but the migration
    # version is not recorded. The table is new and small, so a brief lock is acceptable.
    safety_assured do
      rename_column :hmis_simulation_household_groups, :member_client_ids, :member_relationships if column_exists?(:hmis_simulation_household_groups, :member_client_ids)
    end
  end

  def down
    safety_assured do
      rename_column :hmis_simulation_household_groups, :member_relationships, :member_client_ids if column_exists?(:hmis_simulation_household_groups, :member_relationships)
    end
  end
end
