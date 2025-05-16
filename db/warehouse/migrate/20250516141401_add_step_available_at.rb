###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddStepAvailableAt < ActiveRecord::Migration[7.1]
  def up
    add_column :wfe_steps, :available_at, :datetime, null: true

    safety_assured do
      execute <<~SQL
        UPDATE wfe_steps SET available_at = created_at
      SQL

      change_column_null :wfe_steps, :available_at, false

      # Index because we have to sort steps on this field
      add_index :wfe_steps, :available_at
    end
  end

  def down
    remove_index :wfe_steps, :available_at
    remove_column :wfe_steps, :available_at
  end
end
