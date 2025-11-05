###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateMetricCalculationRuns < ActiveRecord::Migration[7.1]
  def change
    create_table :metric_calculation_runs, comment: 'Log of daily metric calculation jobs' do |t|
      t.string :entity_type, null: false, comment: 'Entity type calculated (e.g., GrdaWarehouse::Hud::Client)'
      t.date :calculation_date, null: false, comment: 'Date for which metrics were calculated'
      t.datetime :started_at, null: false, comment: 'When calculation started'
      t.datetime :completed_at, comment: 'When calculation completed (null if failed/in progress)'

      # High-level summary stats
      t.integer :entities_evaluated_count, default: 0, comment: 'Total entities included in calculation'
      t.integer :metrics_calculated_count, default: 0, comment: 'Total metric calculations performed'
      t.integer :snapshots_created_count, default: 0, comment: 'New snapshots created (crossed threshold)'
      t.integer :snapshots_updated_count, default: 0, comment: 'Existing snapshots updated (extended current_observation_date)'
      t.integer :calculation_errors_count, default: 0, comment: 'Calculations that failed'

      t.string :status, null: false, default: 'running', comment: 'running, completed, failed'
      t.text :error_message, comment: 'Error details if status = failed'

      t.timestamps

      t.index [:entity_type, :calculation_date], unique: true, name: 'index_calculation_runs_unique'
      t.index :calculation_date
      t.index :status
    end
  end
end
