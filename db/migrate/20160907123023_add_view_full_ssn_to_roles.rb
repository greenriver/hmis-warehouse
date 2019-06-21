class AddViewFullSsnToRoles < ActiveRecord::Migration
  # We added an inflector for SSN, noted here in case it breaks the class name
  def up
    Role.ensure_permissions_exist
  end
  def down
    remove_column :roles, :can_view_full_ssn, :boolean, default: false
    remove_column :roles, :can_view_full_dob, :boolean, default: false
    remove_column :roles, :can_view_imports, :boolean, default: false
    remove_column :roles, :can_edit_roles, :boolean, default: false
  end
end
