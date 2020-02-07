class AddBackupPlanArchive < ActiveRecord::Migration[5.2]
  def change
    add_column :careplans, :backup_plan_archive, :text
  end
end
