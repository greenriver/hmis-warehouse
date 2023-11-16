class MakeRolesTablesParanoid < ActiveRecord::Migration[6.1]
  def change
    add_column :roles, :deleted_at, :datetime
  end
end
