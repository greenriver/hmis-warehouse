class RenameCohortPermissions < ActiveRecord::Migration
  def up
    if column_exists? :roles, :can_create_cohorts
      remove_column :roles, :can_create_cohorts, :boolean, default: false
    end
    if column_exists? :roles, :can_view_cohorts
      remove_column :roles, :can_view_cohorts, :boolean, default: false
    end
    Role.ensure_permissions_exist   
  end
  def down
    remove_column :roles, :can_manage_cohorts, :boolean, default: false
    remove_column :roles, :can_edit_cohort_clients, :boolean, default: false
  end
end
