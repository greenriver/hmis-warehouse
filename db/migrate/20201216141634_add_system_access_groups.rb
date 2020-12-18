class AddSystemAccessGroups < ActiveRecord::Migration[5.2]
  def change
    remove_column :access_groups, :system if column_exists?(:access_groups, :system)
    remove_column :access_groups, :required if column_exists?(:access_groups, :required)
    add_column :access_groups, :system, :jsonb, default: []
    add_column :access_groups, :required, :boolean, default: false, null: false
  end
end
