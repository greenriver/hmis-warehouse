###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class RemoveUnitFields < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      # Remove unit_type_id and project_id columns from units table
      # These are no longer needed since units now get this info through unit_group
      # Note: These columns don't have foreign key constraints, so we use remove_column
      remove_column :hmis_units, :unit_type_id, :integer
      remove_column :hmis_units, :project_id, :integer
    end
  end
end
