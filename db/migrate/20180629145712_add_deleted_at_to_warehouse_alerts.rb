class AddDeletedAtToWarehouseAlerts < ActiveRecord::Migration
  def change
    add_column :warehouse_alerts, :deleted_at, :datetime
  end
end
