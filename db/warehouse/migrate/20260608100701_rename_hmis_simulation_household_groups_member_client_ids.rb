###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class RenameHmisSimulationHouseholdGroupsMemberClientIds < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    safety_assured do
      rename_column :hmis_simulation_household_groups, :member_client_ids, :member_relationships
    end
  end
end
