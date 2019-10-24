class AddEnforced2Fa < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end

  def down
    remove_column :roles, :enforced_2fa
  end
end
