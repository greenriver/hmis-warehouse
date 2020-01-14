class AddProjectIDsToRrhTables < ActiveRecord::Migration[4.2]
  def change
    add_column :warehouse_houseds, :project_id, :integer
  end
end
