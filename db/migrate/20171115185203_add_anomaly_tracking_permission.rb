class AddAnomalyTrackingPermission < ActiveRecord::Migration[4.2]
  def up
    Role.ensure_permissions_exist   
  end
  def down
    remove_column :roles, :can_track_anomalies, :boolean, default: false
  end
end
