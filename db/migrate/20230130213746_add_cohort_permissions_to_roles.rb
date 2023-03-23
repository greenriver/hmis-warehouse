class AddCohortPermissionsToRoles < ActiveRecord::Migration[6.1]
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end
  def down
    remove_column :roles, :can_configure_cohorts
    remove_column :roles, :can_add_cohort_clients
    remove_column :roles, :can_manage_cohort_data
    #remove_column :roles, :can_view_cohorts
    remove_column :roles, :can_participate_in_cohorts
    remove_column :roles, :can_view_inactive_cohort_clients
    remove_column :roles, :can_manage_inactive_cohort_clients
    remove_column :roles, :can_view_deleted_cohort_clients
    remove_column :roles, :can_view_cohort_client_changes_report
  end
end
