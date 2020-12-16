class AddSystemAccessGroups < ActiveRecord::Migration[5.2]
  def change
    add_column :access_groups, :system, :jsonb, default: []
    add_column :access_groups, :required, :boolean, default: false, null: false
  end
end
