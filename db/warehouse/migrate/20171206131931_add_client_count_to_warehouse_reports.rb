class AddClientCountToWarehouseReports < ActiveRecord::Migration
  def change
    add_column :warehouse_reports, :client_count, :integer
  end
end
