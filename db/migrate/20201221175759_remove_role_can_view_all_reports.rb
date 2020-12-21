class RemoveRoleCanViewAllReports < ActiveRecord::Migration[5.2]
  def up
    remove_column :roles, :can_view_all_reports
  end
  def down
    add_column :roles, :can_view_all_reports, :boolean, default: false
  end
end
