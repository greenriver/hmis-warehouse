class AlterReportingRoles < ActiveRecord::Migration
  def up
    remove_column :roles, :can_view_reports, :boolean, default: false
    Role.ensure_permissions_exist
    Role.reset_column_information
  end
  def down
    add_column :roles, :can_view_reports, :boolean, default: false
    remove_column :roles, :can_view_all_reports, :boolean, default: false
    remove_column :roles, :can_assign_reports, :boolean, default: false
  end
end
