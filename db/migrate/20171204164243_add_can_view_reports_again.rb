class AddCanViewReportsAgain < ActiveRecord::Migration
  def up
    add_column :roles, :can_view_assigned_reports, :boolean, default: false
    Role.ensure_permissions_exist
    Role.reset_column_information
  end
  def down
    remove_column :roles, :can_view_assigned_reports, :boolean, default: false
  end
end
