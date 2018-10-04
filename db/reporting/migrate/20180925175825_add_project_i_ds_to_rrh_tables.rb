class AddProjectIDsToRrhTables < ActiveRecord::Migration
  def change
    add_column :warehouse_houseds, :project_id, :integer
  end
end
