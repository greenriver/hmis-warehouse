# frozen_string_literal: true

class CreateTaskRuns < ActiveRecord::Migration[7.1]
  def change
    create_table :system_maintenance_tasks do |t|
      t.timestamps
      t.string :registration, null: false
      t.string :name, null: false
      t.integer :alert_threshold_minutes
      t.boolean :active, null: false
      t.index [:registration, :name], unique: true
    end
    create_table :system_maintenance_task_runs do |t|
      t.references :system_maintenance_task
      t.date_time :started_at, null: false
      t.date_time :completed_at
    end
  end
end
