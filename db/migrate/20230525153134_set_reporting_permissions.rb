class SetReportingPermissions < ActiveRecord::Migration[6.1]
  def up
    Role.where(can_view_all_reports: true).update_all(can_view_assigned_reports: true)
  end
end
