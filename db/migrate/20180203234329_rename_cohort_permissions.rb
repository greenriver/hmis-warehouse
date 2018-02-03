class RenameCohortPermissions < ActiveRecord::Migration
  def up
    remove_column :roles, :can_create_cohorts, :boolean, default: false
    remove_column :roles, :can_view_cohorts, :boolean, default: false
    Role.ensure_permissions_exist   
  end
  def down
    remove_column :roles, :can_manage_cohorts, :boolean, default: false
    remove_column :roles, :can_edit_cohort_clients, :boolean, default: false
  end
end
