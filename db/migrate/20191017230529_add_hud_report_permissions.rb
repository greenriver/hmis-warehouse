class AddHudReportPermissions < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
    Role.where(can_view_all_reports: true).update_all(can_view_all_hud_reports: true)
  end

  def down
    remove_column :roles, :can_view_all_hud_reports
    remove_column :roles, :can_view_own_hud_reports
  end
end
