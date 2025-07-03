class UpdateMemoryStorageIntegers < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      change_column :system_maintenance_task_runs, :memory_allocated, :bigint
      change_column :system_maintenance_task_runs, :memory_retained, :bigint
    end
  end
end
