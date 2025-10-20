###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateMetricDefinitions < ActiveRecord::Migration[7.1]
  def change
    create_table :metric_definitions, comment: 'Catalog of available metrics and calculation rules' do |t|
      t.string :name, null: false, limit: 100, comment: 'Unique identifier (e.g., days_homeless_last_three_years)'
      t.string :display_name, null: false, comment: 'Human-readable name for UI'
      t.text :description, comment: 'Detailed description of what this metric measures'
      t.string :entity_type, null: false, comment: 'Entity class this metric applies to (e.g., GrdaWarehouse::Hud::Client)'
      t.string :calculator_class, null: false, comment: 'Ruby class that implements calculation logic'
      t.string :category, limit: 50, comment: 'Grouping category for UI organization'
      t.integer :calculation_window_days, comment: 'Lookback period in days (e.g., 1095 for 3 years)'
      t.integer :count_change_threshold, comment: 'Only create new snapshot if value changes from initial_value by at least this amount'
      t.decimal :percent_change_threshold, precision: 5, scale: 2, comment: 'Only create new snapshot if value changes by at least this percentage'
      t.boolean :active, default: true, null: false, comment: 'Whether this metric is actively being calculated'

      t.timestamps

      t.index [:entity_type, :name], unique: true, name: 'index_metric_defs_on_entity_and_name'
      t.index :active
      t.index :category
    end
  end
end
