# frozen_string_literal: true

class AddMemoryColumnsToSystemMaintenanceTaskRuns < ActiveRecord::Migration[7.1]
  def change
    add_column :system_maintenance_task_runs, :memory_allocated, :integer
    add_column :system_maintenance_task_runs, :memory_retained, :integer
    add_column :system_maintenance_task_runs, :allocation_count, :integer
  end
end
