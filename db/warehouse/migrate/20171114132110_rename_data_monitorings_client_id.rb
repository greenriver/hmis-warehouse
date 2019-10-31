class RenameDataMonitoringsClientId < ActiveRecord::Migration[4.2]
  def change
    rename_column :data_monitorings, :client_id, :resource_id
  end
end
