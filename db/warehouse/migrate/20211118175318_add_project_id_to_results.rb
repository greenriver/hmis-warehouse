class AddProjectIdToResults < ActiveRecord::Migration[5.2]
  def change
    add_column :pm_results, :system_level, :boolean, default: false, null: false
    add_column :pm_results, :project_id, :integer
    add_column :pm_results, :goal, :float
  end
end
