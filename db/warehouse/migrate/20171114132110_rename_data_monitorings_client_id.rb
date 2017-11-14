class RenameDataMonitoringsClientId < ActiveRecord::Migration
  def change
    rename_column :data_monitorings, :client_id, :resource_id
  end
end
