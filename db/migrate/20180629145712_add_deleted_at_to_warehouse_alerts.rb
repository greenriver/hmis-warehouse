class AddDeletedAtToWarehouseAlerts < ActiveRecord::Migration[4.2]
  def change
    add_column :warehouse_alerts, :deleted_at, :datetime
  end
end
