###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class UpdateUnits < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      # Make unit_type_id required on unit_groups table
      change_column_null :hmis_unit_groups, :unit_type_id, false

      # Make hmis_unit_group_id required on units table
      change_column_null :hmis_units, :hmis_unit_group_id, false

      # Remove unit_type_id and project_id columns from units table
      # These are no longer needed since units now get this info through unit_group
      remove_column :hmis_units, :unit_type_id, :integer
      remove_column :hmis_units, :project_id, :integer
    end
  end
end
