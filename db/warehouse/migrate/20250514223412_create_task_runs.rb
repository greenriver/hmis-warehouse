# frozen_string_literal: true

class CreateTaskRuns < ActiveRecord::Migration[7.1]
  def change
    create_table :system_maintenance_tasks do |t|
      t.timestamps
      t.string :job_type, null: false
      t.string :name, null: false
      t.integer :completion_alert_minutes
      t.datetime :alert_sent_at
      t.index [:job_type, :name], unique: true
    end
    create_table :system_maintenance_task_runs do |t|
      t.references :system_maintenance_task, foreign_key: true
      t.datetime :started_at, null: false
      t.datetime :completed_at
    end
  end
end
