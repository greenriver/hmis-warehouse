class AddEnforceProjectVisibilityCohorCells < ActiveRecord::Migration[6.1]
  def change
    add_column :cohorts, :enforce_project_visibility_on_cells, :boolean, null: false, default: true
  end
end
